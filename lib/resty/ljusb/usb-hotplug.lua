local core = require'ljusb.core'
local ffi = require'ffi'
local bit = require'bit'

local bor, band, lshift, rshift = bit.bor, bit.band, bit.lshift, bit.rshift
local new, typeof, metatype = ffi.new, ffi.typeof, ffi.metatype
local cast, C = ffi.cast, ffi.C

ffi.cdef[[
typedef struct ljusb_hotplug {
    libusb_hotplug_callback_handle *handle;
    libusb_hotplug_callback_fn callback;
    void *user_data;
} ljusb_hotplug;
]]

ffi.metatype('struct ljusb_hotplug', {
    __gc = function(t)
        if t.handle ~= nil then
            t.handle[0] = nil
        end
    end
})

local usb_hotplug = {}

usb_hotplug.__index = usb_hotplug

function usb_hotplug.__gc(t)
    if t.context ~= nil then
      t.context = nil
    end
end

function usb_hotplug.__new(context)
    local hp = ffi.new("ljusb_hotplug")
    hp.handle = ffi.new("libusb_hotplug_callback_handle *")
    local ctx = {
        ljusb_hotplug = hp,
        context = context
    }

    return setmetatable(ctx, usb_hotplug)

end

function usb_hotplug:has_capability()
    return core.libusb_has_capability(ffi.C.LIBUSB_CAP_HAS_HOTPLUG) > 0
end

function usb_hotplug:get_raw_handle()
    local h = self.ljusb_hotplug.handle
    assert(h ~= nil)
    return h
end

function usb_hotplug:register(event, callback, vendor_id, product_id, device_class)
    local flag  = ffi.C.LIBUSB_HOTPLUG_ENUMERATE
                  --ffi.C.LIBUSB_HOTPLUG_NO_FLAGS
    local event = event or bor(ffi.C.LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED,
                               ffi.C.LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT)
    local vid   = vendor_id    or ffi.C.LIBUSB_HOTPLUG_MATCH_ANY
    local pid   = product_id   or ffi.C.LIBUSB_HOTPLUG_MATCH_ANY
    local dcs   = device_class or ffi.C.LIBUSB_HOTPLUG_MATCH_ANY

    print("event: ",event)

    if not self.has_capability() then
        return false, "not capability hotplug."
    end

    local user_data = self.ljusb_hotplug


    local cb = ffi.cast("libusb_hotplug_callback_fn",
                function(ctx, dev, event, user_data)
                    print("callback")
                    callback(ctx, dev, event, user_data)
                    --必须返回0，否则只会返调一次。
                    return 0
                end)
    self.ljusb_hotplug.callback = cb

    local handle = self.ljusb_hotplug.handle
    local context = self.context:get_raw_handle()
    local rc = core.libusb_hotplug_register_callback( context, event, flag,
                                                      vid, pid, dcs, cb,
                                                      self.ljusb_hotplug.user_data,
                                                      handle)
    return rc == ffi.C.LIBUSB_SUCCESS
end

function usb_hotplug:dregister()

    if not self.has_capability() then
        return false, "not capability hotplug."
    end

    if not self.get_raw_handle() then
        return false, "not register."
    end

    local context = self.context:get_raw_handle()

    local h = self.ljusb_hotplug
    local hh = h.handle[0]
    local rc = core.libusb_hotplug_deregister_callback(context, hh)

    print("dregister")

    h.callback:free()
    h.callback = nil

    return rc == ffi.C.LIBUSB_SUCCESS
end


return usb_hotplug