package dev.system_contact_picker

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class LegacyFieldSelectionTest {
    @Test
    fun `accepts name with one phone field`() {
        assertEquals(
            "phone",
            SystemContactPickerPlugin.legacyPickerField(listOf("name", "phone")),
        )
    }

    @Test
    fun `accepts name with each supported legacy value field`() {
        assertEquals(
            "email",
            SystemContactPickerPlugin.legacyPickerField(listOf("name", "email")),
        )
        assertEquals(
            "postalAddress",
            SystemContactPickerPlugin.legacyPickerField(listOf("name", "postalAddress")),
        )
    }

    @Test
    fun `accepts standalone name or value field`() {
        assertEquals(
            "name",
            SystemContactPickerPlugin.legacyPickerField(listOf("name")),
        )
        assertEquals(
            "phone",
            SystemContactPickerPlugin.legacyPickerField(listOf("phone")),
        )
    }

    @Test
    fun `rejects multiple value fields and unsupported fields`() {
        assertNull(
            SystemContactPickerPlugin.legacyPickerField(listOf("name", "phone", "email")),
        )
        assertNull(SystemContactPickerPlugin.legacyPickerField(listOf("organization")))
        assertNull(SystemContactPickerPlugin.legacyPickerField(emptyList()))
    }
}
