local core = require'ljusb.core'
local ffi = require'ffi'
local bit = require'bit'

local usb_device_handle = require "ljusb.device.handle"

ffi.cdef[[
typedef struct ljusb_device {
    struct libusb_device *handle;
} ljusb_device;
]]

ffi.metatype('struct ljusb_device', {
    __gc = function(t)
        if t.handle ~= nil then
            core.libusb_unref_device(t.handle)
            t.handle = nil
        end
    end
})

local usb_device = {}
usb_device.__index = usb_device

function usb_device:__tostring()
    return "usb_device"
end

function usb_device.__new(context, device)
    local dev = {
        ljusb_device = ffi.new("ljusb_device") ,
        context = context,
    }
    dev.ljusb_device.handle = core.libusb_ref_device(device)
    if dev.ljusb_device.handle ~= nil then
        return setmetatable(dev, usb_device)
    else
        return nil
    end
end

function usb_device:get_device_port_numbers()
    local max_len = 8 -- libusb doc says limit is 7
    local memory = ffi.gc(ffi.C.malloc(max_len), ffi.C.free)
    local buffer = ffi.cast("uint8_t*", memory)
    local r = core.libusb_get_port_numbers(self:get_raw_handle(), buffer, max_len)
    if r < ffi.C.LIBUSB_SUCCESS then
        return nil, r
    end
    local path = {}
    for i=0,r-1 do
        table.insert(path, buffer[i])
    end
    return path
end

function usb_device:get_device_port_numbers_string(dev)
    local path, err = self:get_device_port_numbers(dev)
    if not path then
        return nil, err
    end
    return table.concat(path, ".")
end

function usb_device:get_raw_handle()
    local h = self.ljusb_device.handle
    assert(h ~= nil)
    return h
end

function usb_device:open()
    --TODO store as weak
    return usb_device_handle.__open_device(self.context, self)
end

function usb_device:get_descriptor()
    if not self.descriptor then
        local desc = ffi.new("struct libusb_device_descriptor ")
        local r = core.libusb_get_device_descriptor(self:get_raw_handle(), desc)
        if r == ffi.C.LIBUSB_SUCCESS then
            self.descriptor = desc
            return desc
        end
        error("Failed to get device descriptor: " .. error_str(r))
    end
    return self.descriptor
end

function usb_device:get_vid_pid()
    local d = self:get_descriptor()
    return { vid=d.idVendor, pid=d.idProduct }
end

function usb_device:get_product_manufacturer_serial()
    local d = self:get_descriptor()
    local h, c = self:open()
    if not h then
        return nil, c
    end
    local product = h:get_string_descriptor_ascii(d.iProduct)
    local manufacturer = h:get_string_descriptor_ascii(d.iManufacturer)
    local serial = h:get_string_descriptor_ascii(d.iSerialNumber)
    local conf_num   = d.bNumConfigurations
    return { product=product, manufacturer=manufacturer, serial=serial, conf_num = conf_num }
end

function usb_device:get_config_descriptor(index)
    local conf_desc  = ffi.new("struct libusb_config_descriptor *[1]")
    local desc = self:get_descriptor()

    local conf_num = desc.bNumConfigurations
    if index > conf_num -1 or index < 0 then
        return nil, " index over range. "
    end

    local r = core.libusb_get_config_descriptor(self:get_raw_handle(), index, conf_desc)

    if r == ffi.C.LIBUSB_SUCCESS then
        return conf_desc[0]
    end
    return nil, self:error_string(r)
end

function usb_device:get_interface_info_by_class(interface_class_id)

    local interface_num, endpoint_in, endpoint_out
    local d = self:get_descriptor()
    local conf_num   = d.bNumConfigurations
    for i = 0, conf_num -1 do
        local conf_desc = self:get_config_descriptor(i)
        local num_interfaces = conf_desc.bNumInterfaces
        for j = 0, num_interfaces -1 do
            local interface = conf_desc.interface[j]
            local num_altsetting = interface.num_altsetting
            for k = 0, num_altsetting -1 do
                local altsetting = interface.altsetting[k]
                if altsetting.bInterfaceClass == interface_class_id then
                    interface_num = altsetting.bInterfaceNumber
                    local endpoint = altsetting.endpoint
                    local num_endpoint = altsetting.bNumEndpoints
                    for l = 0 , num_endpoint - 1 do
                        if bit.rshift(endpoint[l].bEndpointAddress,7) == 1 then
                            endpoint_in = endpoint[l].bEndpointAddress
                        else
                            endpoint_out = endpoint[l].bEndpointAddress
                        end
                    end
                    print("interface num: ", interface_num,
                          "  ep_in: ", endpoint_in ,
                          " ep_out: ", endpoint_out)
                    return {
                        interface_num = interface_num,
                        ep_in  = endpoint_in,
                        ep_out = endpoint_out }
                end
            end
        end
    end
    return false, "not found."
end
return usb_device
