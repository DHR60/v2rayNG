package com.v2ray.ang.fmt

import com.v2ray.ang.dto.ProfileItem
import com.v2ray.ang.dto.V2rayConfig.OutboundBean
import com.v2ray.ang.enums.EConfigType
import com.v2ray.ang.extension.isNotNullEmpty
import com.v2ray.ang.handler.V2rayConfigManager

object HttpFmt : FmtBase() {
    /**
     * Converts a ProfileItem object to an OutboundBean object.
     *
     * @param profileItem the ProfileItem object to convert
     * @return the converted OutboundBean object, or null if conversion fails
     */
    fun toOutbound(profileItem: ProfileItem): OutboundBean? {
        val outboundBean = V2rayConfigManager.createInitOutbound(EConfigType.HTTP)

        outboundBean?.settings?.let { settings ->
            settings.address = getServerAddress(profileItem)
            settings.port = profileItem.serverPort.orEmpty().toInt()
            if (profileItem.username.isNotNullEmpty()) {
                settings.user = profileItem.username.orEmpty()
                settings.pass = profileItem.password.orEmpty()
            }
        }

        return outboundBean
    }
}