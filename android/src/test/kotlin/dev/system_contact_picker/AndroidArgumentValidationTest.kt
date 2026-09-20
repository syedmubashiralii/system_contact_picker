package dev.system_contact_picker

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
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class AndroidArgumentValidationTest {
    @Test
    fun `uses safe defaults when arguments are absent`() {
        val options = SystemContactPickerPlugin.PickerOptions.fromArguments(null)

        assertEquals(listOf("phone"), options.fields)
        assertEquals(false, options.allowMultiple)
        assertEquals(null, options.limit)
        assertEquals(false, options.matchAllFields)
    }

    @Test
    fun `normalizes duplicate fields and accepts codec integer types`() {
        val options = SystemContactPickerPlugin.PickerOptions.fromArguments(
            mapOf(
                "fields" to listOf("name", "phone", "phone"),
                "allowMultiple" to true,
                "limit" to 100L,
                "matchAllFields" to true,
            ),
        )

        assertEquals(listOf("name", "phone"), options.fields)
        assertEquals(true, options.allowMultiple)
        assertEquals(100, options.limit)
        assertEquals(true, options.matchAllFields)
    }

    @Test
    fun `rejects malformed argument containers and field values`() {
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments("not-a-map")
        }
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments(
                mapOf("fields" to "phone"),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments(
                mapOf("fields" to listOf("phone", 7)),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments(
                mapOf("fields" to listOf("unknown")),
            )
        }
    }

    @Test
    fun `rejects malformed booleans and limits before launching`() {
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments(
                mapOf("allowMultiple" to 1),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            SystemContactPickerPlugin.PickerOptions.fromArguments(
                mapOf("matchAllFields" to "true"),
            )
        }
        for (limit in listOf(0, 101, Int.MAX_VALUE, Long.MAX_VALUE, 1.5)) {
            assertFailsWith<IllegalArgumentException>("limit=$limit") {
                SystemContactPickerPlugin.PickerOptions.fromArguments(
                    mapOf("limit" to limit),
                )
            }
        }
    }

    @Test
    fun `selects the picker implementation at the Android 17 boundary`() {
        for (sdkInt in listOf(24, 28, 35, 36)) {
            assertFalse(SystemContactPickerPlugin.usesAndroid17Picker(sdkInt))
        }
        for (sdkInt in listOf(37, 38, Int.MAX_VALUE)) {
            assertTrue(SystemContactPickerPlugin.usesAndroid17Picker(sdkInt))
        }
    }

    @Test
    fun `maps every Android 17 field to an allowed picker MIME type`() {
        assertEquals(
            listOf(
                StructuredName.CONTENT_ITEM_TYPE,
                Phone.CONTENT_ITEM_TYPE,
                Email.CONTENT_ITEM_TYPE,
                StructuredPostal.CONTENT_ITEM_TYPE,
                Organization.CONTENT_ITEM_TYPE,
                Relation.CONTENT_ITEM_TYPE,
                Event.CONTENT_ITEM_TYPE,
                Photo.CONTENT_ITEM_TYPE,
                Website.CONTENT_ITEM_TYPE,
                Nickname.CONTENT_ITEM_TYPE,
            ),
            SystemContactPickerPlugin.requestedMimeTypes(
                listOf(
                    "name",
                    "phone",
                    "email",
                    "postalAddress",
                    "organization",
                    "relation",
                    "event",
                    "photo",
                    "website",
                    "nickname",
                ),
            ),
        )
    }
}
