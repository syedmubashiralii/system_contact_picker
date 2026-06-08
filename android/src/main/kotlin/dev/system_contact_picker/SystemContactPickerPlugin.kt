package dev.system_contact_picker

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.Email
import android.provider.ContactsContract.CommonDataKinds.Event
import android.provider.ContactsContract.CommonDataKinds.Nickname
import android.provider.ContactsContract.CommonDataKinds.Organization
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.provider.ContactsContract.CommonDataKinds.Photo
import android.provider.ContactsContract.CommonDataKinds.Relation
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal
import android.provider.ContactsContract.CommonDataKinds.Website
import android.provider.ContactsContract.Data
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class SystemContactPickerPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var appContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingCall: PendingCall? = null
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "system_contact_picker")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pickContacts" -> handlePickContacts(call, result)
            "getCapabilities" -> result.success(capabilities())
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        if (requestCode != REQUEST_PICK_CONTACT) {
            return false
        }
        val current = pendingCall ?: return true
        if (resultCode != Activity.RESULT_OK) {
            completeSuccess(current, emptyList())
            return true
        }

        val resultUri = data?.data
        if (resultUri == null) {
            completeSuccess(current, emptyList())
            return true
        }

        executor.execute {
            try {
                val contacts = if (usesAndroid17Picker()) {
                    queryAndroid17Session(resultUri)
                } else {
                    queryLegacyContact(resultUri, current.options)
                }
                completeSuccess(current, contacts)
            } catch (error: Throwable) {
                completeError(
                    current,
                    "query_failed",
                    error.message ?: "Unable to read the selected contact data.",
                )
            }
        }
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != REQUEST_READ_CONTACTS) {
            return false
        }
        val current = pendingCall ?: return true
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            launchPicker(current)
        } else {
            completeError(
                current,
                "permission_denied",
                "READ_CONTACTS permission is required for the legacy Android picker on API 36 and below.",
            )
        }
        return true
    }

    private fun handlePickContacts(call: MethodCall, result: Result) {
        val hostActivity = activity
        if (hostActivity == null) {
            result.error(
                "activity_unavailable",
                "Contact picker requires a foreground Flutter activity.",
                null,
            )
            return
        }
        if (pendingCall != null) {
            result.error("already_active", "A contact picker request is already active.", null)
            return
        }

        val options = try {
            PickerOptions.from(call)
        } catch (error: IllegalArgumentException) {
            result.error("bad_arguments", error.message, null)
            return
        }

        val current = PendingCall(result, options)
        pendingCall = current

        if (!usesAndroid17Picker() && !hasReadContactsPermission(hostActivity)) {
            hostActivity.requestPermissions(
                arrayOf(Manifest.permission.READ_CONTACTS),
                REQUEST_READ_CONTACTS,
            )
            return
        }

        launchPicker(current)
    }

    private fun launchPicker(current: PendingCall) {
        val hostActivity = activity
        if (hostActivity == null) {
            completeError(
                current,
                "activity_unavailable",
                "Contact picker requires a foreground Flutter activity.",
            )
            return
        }
        val intent = if (usesAndroid17Picker()) {
            android17Intent(current.options)
        } else {
            legacyIntent(current.options)
        }
        try {
            hostActivity.startActivityForResult(intent, REQUEST_PICK_CONTACT)
        } catch (error: ActivityNotFoundException) {
            completeError(
                current,
                "activity_not_found",
                "No contacts picker activity is available on this device.",
            )
        } catch (error: Throwable) {
            completeError(current, "launch_failed", error.message ?: "Unable to launch picker.")
        }
    }

    private fun android17Intent(options: PickerOptions): Intent {
        return Intent(ACTION_PICK_CONTACTS).apply {
            putExtra(EXTRA_USE_SYSTEM_CONTACTS_PICKER, true)
            putStringArrayListExtra(
                EXTRA_PICK_CONTACTS_REQUESTED_DATA_FIELDS,
                ArrayList(requestedMimeTypes(options.fields)),
            )
            putExtra(EXTRA_PICK_CONTACTS_MATCH_ALL_DATA_FIELDS, options.matchAllFields)
            if (options.allowMultiple) {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                options.limit?.let { putExtra(EXTRA_PICK_CONTACTS_SELECTION_LIMIT, it) }
            }
        }
    }

    private fun legacyIntent(options: PickerOptions): Intent {
        val dataUri = when {
            options.fields.size == 1 && options.fields.contains("phone") -> Phone.CONTENT_URI
            options.fields.size == 1 && options.fields.contains("email") -> Email.CONTENT_URI
            options.fields.size == 1 && options.fields.contains("postalAddress") ->
                StructuredPostal.CONTENT_URI
            else -> ContactsContract.Contacts.CONTENT_URI
        }
        return Intent(Intent.ACTION_PICK, dataUri).apply {
            putExtra(EXTRA_USE_SYSTEM_CONTACTS_PICKER, true)
        }
    }

    private fun queryAndroid17Session(sessionUri: Uri): List<Map<String, Any?>> {
        val context = appContext ?: error("Missing application context.")
        val contacts = LinkedHashMap<String, ContactBuilder>()
        context.contentResolver.query(sessionUri, DATA_PROJECTION, null, null, null)?.use { cursor ->
            readDataCursor(cursor, contacts)
        }
        return contacts.values.map { it.toMap() }
    }

    private fun queryLegacyContact(
        uri: Uri,
        options: PickerOptions
    ): List<Map<String, Any?>> {
        val context = appContext ?: error("Missing application context.")
        val contactId = resolveLegacyContactId(context, uri) ?: return emptyList()
        val mimeTypes = requestedMimeTypes(options.fields)
        val contacts = LinkedHashMap<String, ContactBuilder>()
        val placeholders = mimeTypes.joinToString(",") { "?" }
        val selection = buildString {
            append("${Data.CONTACT_ID} = ?")
            if (mimeTypes.isNotEmpty()) {
                append(" AND ${Data.MIMETYPE} IN ($placeholders)")
            }
        }
        val selectionArgs = arrayOf(contactId, *mimeTypes.toTypedArray())
        context.contentResolver.query(
            Data.CONTENT_URI,
            DATA_PROJECTION,
            selection,
            selectionArgs,
            null,
        )?.use { cursor ->
            readDataCursor(cursor, contacts)
        }
        return contacts.values.map { it.toMap() }
    }

    private fun resolveLegacyContactId(context: Context, uri: Uri): String? {
        val projections = listOf(
            arrayOf(Data.CONTACT_ID),
            arrayOf(ContactsContract.Contacts._ID),
        )
        for (projection in projections) {
            try {
                context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getStringOrNull(projection[0])
                        if (!id.isNullOrBlank()) {
                            return id
                        }
                    }
                }
            } catch (_: Throwable) {
                continue
            }
        }
        return null
    }

    private fun readDataCursor(
        cursor: Cursor,
        contacts: LinkedHashMap<String, ContactBuilder>
    ) {
        while (cursor.moveToNext()) {
            val id = cursor.getStringOrNull(Data.LOOKUP_KEY)
                ?: cursor.getStringOrNull(Data.CONTACT_ID)
                ?: continue
            val contact = contacts.getOrPut(id) { ContactBuilder(id) }
            contact.lookupKey = cursor.getStringOrNull(Data.LOOKUP_KEY) ?: contact.lookupKey
            val displayName = cursor.getStringOrNull(Data.DISPLAY_NAME_PRIMARY)
            if (!displayName.isNullOrBlank()) {
                contact.displayName = displayName
            }

            when (cursor.getStringOrNull(Data.MIMETYPE)) {
                StructuredName.CONTENT_ITEM_TYPE -> contact.applyStructuredName(cursor)
                Phone.CONTENT_ITEM_TYPE -> contact.addPhone(cursor)
                Email.CONTENT_ITEM_TYPE -> contact.addEmail(cursor)
                StructuredPostal.CONTENT_ITEM_TYPE -> contact.addPostalAddress(cursor)
                Organization.CONTENT_ITEM_TYPE -> contact.addOrganization(cursor)
                Website.CONTENT_ITEM_TYPE -> contact.addWebsite(cursor)
                Relation.CONTENT_ITEM_TYPE -> contact.addRelation(cursor)
                Event.CONTENT_ITEM_TYPE -> contact.addEvent(cursor)
                Nickname.CONTENT_ITEM_TYPE -> contact.addNickname(cursor)
                Photo.CONTENT_ITEM_TYPE -> contact.thumbnail = cursor.getBlobOrNull(Photo.PHOTO)
            }
        }
    }

    private fun requestedMimeTypes(fields: List<String>): List<String> {
        val mimeTypes = LinkedHashSet<String>()
        for (field in fields) {
            when (field) {
                "name" -> mimeTypes.add(StructuredName.CONTENT_ITEM_TYPE)
                "phone" -> mimeTypes.add(Phone.CONTENT_ITEM_TYPE)
                "email" -> mimeTypes.add(Email.CONTENT_ITEM_TYPE)
                "postalAddress" -> mimeTypes.add(StructuredPostal.CONTENT_ITEM_TYPE)
                "organization" -> mimeTypes.add(Organization.CONTENT_ITEM_TYPE)
                "relation" -> mimeTypes.add(Relation.CONTENT_ITEM_TYPE)
                "event" -> mimeTypes.add(Event.CONTENT_ITEM_TYPE)
                "photo" -> mimeTypes.add(Photo.CONTENT_ITEM_TYPE)
                "website" -> mimeTypes.add(Website.CONTENT_ITEM_TYPE)
                "nickname" -> mimeTypes.add(Nickname.CONTENT_ITEM_TYPE)
                else -> throw IllegalArgumentException("Unsupported contact field: $field")
            }
        }
        return mimeTypes.toList()
    }

    private fun hasReadContactsPermission(hostActivity: Activity): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            hostActivity.checkSelfPermission(Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun usesAndroid17Picker(): Boolean {
        return Build.VERSION.SDK_INT >= ANDROID_17_API
    }

    private fun capabilities(): Map<String, Any?> {
        val android17 = usesAndroid17Picker()
        return mapOf(
            "platform" to "android",
            "androidSdkInt" to Build.VERSION.SDK_INT,
            "usesAndroid17ContactPicker" to android17,
            "supportsMultiple" to android17,
            "requiresReadContactsPermission" to !android17,
            "maximumSelectionLimit" to if (android17) MAX_SELECTION_LIMIT else 1,
        )
    }

    private fun completeSuccess(current: PendingCall, contacts: List<Map<String, Any?>>) {
        mainHandler.post {
            if (pendingCall !== current) {
                return@post
            }
            pendingCall = null
            current.result.success(contacts)
        }
    }

    private fun completeError(current: PendingCall, code: String, message: String) {
        mainHandler.post {
            if (pendingCall !== current) {
                return@post
            }
            pendingCall = null
            current.result.error(code, message, null)
        }
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        pendingCall?.let {
            completeError(
                it,
                "activity_detached",
                "Flutter activity detached before the contact picker completed.",
            )
        }
    }

    private inner class ContactBuilder(private val id: String) {
        var lookupKey: String? = null
        var displayName: String = ""
        var givenName: String? = null
        var middleName: String? = null
        var familyName: String? = null
        var namePrefix: String? = null
        var nameSuffix: String? = null
        var thumbnail: ByteArray? = null
        private val phones = mutableListOf<Map<String, Any?>>()
        private val emails = mutableListOf<Map<String, Any?>>()
        private val postalAddresses = mutableListOf<Map<String, Any?>>()
        private val organizations = mutableListOf<Map<String, Any?>>()
        private val websites = mutableListOf<Map<String, Any?>>()
        private val relations = mutableListOf<Map<String, Any?>>()
        private val events = mutableListOf<Map<String, Any?>>()
        private val nicknames = mutableListOf<Map<String, Any?>>()

        fun applyStructuredName(cursor: Cursor) {
            givenName = cursor.getStringOrNull(StructuredName.GIVEN_NAME) ?: givenName
            middleName = cursor.getStringOrNull(StructuredName.MIDDLE_NAME) ?: middleName
            familyName = cursor.getStringOrNull(StructuredName.FAMILY_NAME) ?: familyName
            namePrefix = cursor.getStringOrNull(StructuredName.PREFIX) ?: namePrefix
            nameSuffix = cursor.getStringOrNull(StructuredName.SUFFIX) ?: nameSuffix
        }

        fun addPhone(cursor: Cursor) {
            val number = cursor.getStringOrNull(Phone.NUMBER) ?: return
            phones.add(
                dataItem(
                    value = number,
                    label = typeLabel(cursor, Phone.TYPE, Phone.LABEL) { type, label ->
                        Phone.getTypeLabel(resources(), type, label).toString()
                    },
                    type = cursor.getIntOrNull(Phone.TYPE)?.toString(),
                    normalizedValue = cursor.getStringOrNull(Phone.NORMALIZED_NUMBER),
                ),
            )
        }

        fun addEmail(cursor: Cursor) {
            val address = cursor.getStringOrNull(Email.ADDRESS) ?: return
            emails.add(
                dataItem(
                    value = address,
                    label = typeLabel(cursor, Email.TYPE, Email.LABEL) { type, label ->
                        Email.getTypeLabel(resources(), type, label).toString()
                    },
                    type = cursor.getIntOrNull(Email.TYPE)?.toString(),
                ),
            )
        }

        fun addPostalAddress(cursor: Cursor) {
            val type = cursor.getIntOrNull(StructuredPostal.TYPE)
            val customLabel = cursor.getStringOrNull(StructuredPostal.LABEL)
            postalAddresses.add(
                mapOf(
                    "formatted" to cursor.getStringOrNull(StructuredPostal.FORMATTED_ADDRESS),
                    "street" to cursor.getStringOrNull(StructuredPostal.STREET),
                    "city" to cursor.getStringOrNull(StructuredPostal.CITY),
                    "region" to cursor.getStringOrNull(StructuredPostal.REGION),
                    "postalCode" to cursor.getStringOrNull(StructuredPostal.POSTCODE),
                    "country" to cursor.getStringOrNull(StructuredPostal.COUNTRY),
                    "label" to if (type == null) {
                        customLabel
                    } else {
                        StructuredPostal.getTypeLabel(resources(), type, customLabel).toString()
                    },
                    "type" to type?.toString(),
                ).withoutNulls(),
            )
        }

        fun addOrganization(cursor: Cursor) {
            organizations.add(
                mapOf(
                    "company" to cursor.getStringOrNull(Organization.COMPANY),
                    "department" to cursor.getStringOrNull(Organization.DEPARTMENT),
                    "title" to cursor.getStringOrNull(Organization.TITLE),
                    "label" to cursor.getStringOrNull(Organization.LABEL),
                    "type" to cursor.getIntOrNull(Organization.TYPE)?.toString(),
                ).withoutNulls(),
            )
        }

        fun addWebsite(cursor: Cursor) {
            val url = cursor.getStringOrNull(Website.URL) ?: return
            websites.add(
                dataItem(
                    value = url,
                    label = cursor.getStringOrNull(Website.LABEL),
                    type = cursor.getIntOrNull(Website.TYPE)?.toString(),
                ),
            )
        }

        fun addRelation(cursor: Cursor) {
            val name = cursor.getStringOrNull(Relation.NAME) ?: return
            relations.add(
                dataItem(
                    value = name,
                    label = cursor.getStringOrNull(Relation.LABEL),
                    type = cursor.getIntOrNull(Relation.TYPE)?.toString(),
                ),
            )
        }

        fun addEvent(cursor: Cursor) {
            val date = cursor.getStringOrNull(Event.START_DATE) ?: return
            events.add(
                dataItem(
                    value = date,
                    label = cursor.getStringOrNull(Event.LABEL),
                    type = cursor.getIntOrNull(Event.TYPE)?.toString(),
                ),
            )
        }

        fun addNickname(cursor: Cursor) {
            val name = cursor.getStringOrNull(Nickname.NAME) ?: return
            nicknames.add(
                dataItem(
                    value = name,
                    label = cursor.getStringOrNull(Data.DATA3),
                    type = cursor.getIntOrNull(Nickname.TYPE)?.toString(),
                ),
            )
        }

        fun toMap(): Map<String, Any?> {
            return mapOf(
                "id" to id,
                "lookupKey" to lookupKey,
                "displayName" to displayName,
                "givenName" to givenName,
                "middleName" to middleName,
                "familyName" to familyName,
                "namePrefix" to namePrefix,
                "nameSuffix" to nameSuffix,
                "phones" to phones,
                "emails" to emails,
                "postalAddresses" to postalAddresses,
                "organizations" to organizations,
                "websites" to websites,
                "relations" to relations,
                "events" to events,
                "nicknames" to nicknames,
                "thumbnail" to thumbnail,
            ).withoutNulls()
        }

        private fun resources() = appContext?.resources ?: activity?.resources
            ?: throw IllegalStateException("Missing Android resources.")
    }

    private data class PickerOptions(
        val fields: List<String>,
        val allowMultiple: Boolean,
        val limit: Int?,
        val matchAllFields: Boolean,
    ) {
        companion object {
            fun from(call: MethodCall): PickerOptions {
                val fields = (call.argument<List<String>>("fields") ?: DEFAULT_FIELDS)
                    .distinct()
                require(fields.isNotEmpty()) { "At least one contact field is required." }
                val limit = (call.argument<Any>("limit") as? Number)?.toInt()
                require(limit == null || limit in 1..MAX_SELECTION_LIMIT) {
                    "limit must be between 1 and $MAX_SELECTION_LIMIT."
                }
                return PickerOptions(
                    fields = fields,
                    allowMultiple = call.argument<Boolean>("allowMultiple") ?: false,
                    limit = limit,
                    matchAllFields = call.argument<Boolean>("matchAllFields") ?: false,
                )
            }
        }
    }

    private data class PendingCall(
        val result: Result,
        val options: PickerOptions,
    )

    private fun dataItem(
        value: String,
        label: String? = null,
        type: String? = null,
        normalizedValue: String? = null
    ): Map<String, Any?> {
        return mapOf(
            "value" to value,
            "label" to label,
            "type" to type,
            "normalizedValue" to normalizedValue,
        ).withoutNulls()
    }

    private fun typeLabel(
        cursor: Cursor,
        typeColumn: String,
        labelColumn: String,
        formatter: (Int, String?) -> String
    ): String? {
        val type = cursor.getIntOrNull(typeColumn) ?: return cursor.getStringOrNull(labelColumn)
        return formatter(type, cursor.getStringOrNull(labelColumn))
    }

    private fun Cursor.getStringOrNull(column: String): String? {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return null
        }
        return getString(index)
    }

    private fun Cursor.getIntOrNull(column: String): Int? {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return null
        }
        return getInt(index)
    }

    private fun Cursor.getBlobOrNull(column: String): ByteArray? {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return null
        }
        return getBlob(index)
    }

    private fun Map<String, Any?>.withoutNulls(): Map<String, Any?> {
        return filterValues { it != null }
    }

    companion object {
        private const val ANDROID_17_API = 37
        private const val REQUEST_PICK_CONTACT = 3717
        private const val REQUEST_READ_CONTACTS = 3718
        private const val MAX_SELECTION_LIMIT = 100
        private const val ACTION_PICK_CONTACTS = "android.provider.action.PICK_CONTACTS"
        private const val EXTRA_USE_SYSTEM_CONTACTS_PICKER =
            "android.intent.extra.USE_SYSTEM_CONTACTS_PICKER"
        private const val EXTRA_PICK_CONTACTS_REQUESTED_DATA_FIELDS =
            "android.provider.extra.PICK_CONTACTS_REQUESTED_DATA_FIELDS"
        private const val EXTRA_PICK_CONTACTS_SELECTION_LIMIT =
            "android.provider.extra.PICK_CONTACTS_SELECTION_LIMIT"
        private const val EXTRA_PICK_CONTACTS_MATCH_ALL_DATA_FIELDS =
            "android.provider.extra.PICK_CONTACTS_MATCH_ALL_DATA_FIELDS"
        private val DEFAULT_FIELDS = listOf("phone", "email")
        private val DATA_PROJECTION = arrayOf(
            Data.CONTACT_ID,
            Data.LOOKUP_KEY,
            Data.DISPLAY_NAME_PRIMARY,
            Data.MIMETYPE,
            Data.DATA1,
            Data.DATA2,
            Data.DATA3,
            Data.DATA4,
            Data.DATA5,
            Data.DATA6,
            Data.DATA7,
            Data.DATA8,
            Data.DATA9,
            Data.DATA10,
            Data.DATA11,
            Data.DATA12,
            Data.DATA13,
            Data.DATA14,
            Data.DATA15,
        )
    }
}
