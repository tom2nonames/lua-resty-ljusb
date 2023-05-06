local core = require'ljusb.core'
local ffi = require'ffi'
local bit = require'bit'

local bor, band, lshift, rshift = bit.bor, bit.band, bit.lshift, bit.rshift
local new, typeof, metatype = ffi.new, ffi.typeof, ffi.metatype
local cast, C = ffi.cast, ffi.C

ffi.cdef[[
typedef struct ljusb_transfer {
    struct libusb_transfer *handle;
} ljusb_transfer;
]]

ffi.metatype('struct ljusb_transfer', {
    __gc = function(t)
        if t.handle.callback ~= nil then
            t.handle.callback:free()
        end
        core.libusb_free_transfer(t.handle)
    end
})

local usb_transfer = {}
usb_transfer.__index = usb_transfer

function usb_transfer.__new(iso_cnt)
    local tr = {
        ljusb_transfer = ffi.new("ljusb_transfer")
    }
    tr.ljusb_transfer.handle = core.libusb_alloc_transfer(iso_cnt or 0)
    return setmetatable(tr, usb_transfer)
end

function usb_transfer:get_raw_handle()
    local h = self.ljusb_transfer.handle
    assert(h ~= nil)
    return h
end

function usb_transfer:control_setup(bRequestType, bRequest, wValue, wIndex, data)
    self:set_data(data)

    local t = self:get_raw_handle()
    t.buffer[0] = bRequestType
    t.buffer[1] = bRequest
    t.buffer[2] = band(wValue, 0xff)
    t.buffer[3] = band(rshift(wValue, 8), 0xff)
    t.buffer[4] = band(wIndex, 0xff)
    t.buffer[5] = band(rshift(wIndex, 8), 0xff)

    return self
end

function usb_transfer:data()
    local t = self:get_raw_handle()
    if t.actual_length == 0 then
        return ""
    end
    return ffi.string(t.buffer + ffi.C.LIBUSB_CONTROL_SETUP_SIZE, t.actual_length)
end

function usb_transfer:set_data(data, not_control_setup)
    local t = self:get_raw_handle()

    if data == nil and t.length >= ffi.C.LIBUSB_CONTROL_SETUP_SIZE then
        return
    end

    local data_len = 0
    if data == nil then
        data = ""
    elseif type(data) == "number" then
        data_len = data
        data = ""
    else
        data_len = data:len()
    end

    local setup_size = ffi.C.LIBUSB_CONTROL_SETUP_SIZE
    if not_control_setup then
        setup_size = 0
    end

    local len = setup_size + data_len

    if t.length < len then
        t.buffer = ffi.gc(ffi.C.malloc(len), ffi.C.free)
    end
    if data:len() > 0 then
        ffi.copy(t.buffer + setup_size, data, data:len())
    end

    t.length = len
    if not not_control_setup then
        t.actual_length = data:len()
        t.buffer[6] = band(data_len, 0xff)
        t.buffer[7] = band(rshift(data_len, 8), 0xff)
    end
    return self
end

function usb_transfer:unpack_data(fmt)
    local struct = require "struct"
    local d = self:data()
    if d:len() > 0 then
        return struct.unpack(fmt, d)
    else
        return nil
    end
end

function usb_transfer:pack_data(fmt, ...)
    local struct = require "struct"
    return self:set_data(struct.pack(fmt, ...))
end

function usb_transfer:submit(dev_hnd, cb, timeout)
    local t = self:get_raw_handle()
    t.dev_handle = dev_hnd:get_raw_handle()
    t.callback = ffi.new('libusb_transfer_cb_fn', function()
        cb(self)
        local t = self:get_raw_handle()
        t.callback:free()
        t.callback = nil
    end)
    t.timeout = timeout or 0
    local err = core.libusb_submit_transfer(t)

    if err ~= ffi.C.LIBUSB_SUCCESS then
        print('transfer submit error - ' .. ffi.string(core.libusb_error_name(err)))
        return false, err
    end
    return true
end

function usb_transfer:cancel()
    local t = self:get_raw_handle()
    local err = core.libusb_cancel_transfer(t)
    if err ~= ffi.C.LIBUSB_SUCCESS then
        return  false, err
    end
    return true
end

local little_endian = ffi.abi'le'
local libusb_control_setup_ptr = typeof'struct libusb_control_setup *'

local function libusb_cpu_to_le16(i)
    i = band(i, 0xffff)
    if little_endian then
      return i
    else
      return bor(lshift(i, 8), rshift(i, 8))
    end
end

function usb_transfer:fill_control(bmRequestType, bRequest, wValue, wIndex, data)
    self:control_setup(bmRequestType, bRequest, wValue, wIndex, data)
    local t = self:get_raw_handle()

    local setup = cast(libusb_control_setup_ptr, t.buffer)
    t.endpoint = 0
    t.type = core.LIBUSB_TRANSFER_TYPE_CONTROL
    if setup ~= nil then
        t.length = core.LIBUSB_CONTROL_SETUP_SIZE +
        libusb_cpu_to_le16(setup.wLength)
    end

    return self
end

function usb_transfer:fill_bulk(endpoint, data)
    self:set_data(data, true)
    local t = self:get_raw_handle()
    t.endpoint = endpoint
    t.type = core.LIBUSB_TRANSFER_TYPE_BULK
    return self
end

function usb_transfer:fill_bulk_stream(endpoint, stream_id, data)
    self:fill_bulk(endpoint, data)
    local t = self:get_raw_handle()
    t.type = core.LIBUSB_TRANSFER_TYPE_BULK_STREAM
    core.libusb_transfer_set_stream_id(t, stream_id)
    return self
end

function usb_transfer:fill_iso(endpoint, num_iso_packets, data)
    self:set_data(data, true)
    local t = self:get_raw_handle()
    t.endpoint = endpoint
    t.num_iso_packets = num_iso_packets
    t.type = core.LIBUSB_TRANSFER_TYPE_ISOCHRONOUS
    return self
end

function usb_transfer:fill_interrupt(endpoint, data)
    self:set_data(data, true)
    local t = self:get_raw_handle()
    t.endpoint = endpoint
    t.type = core.LIBUSB_TRANSFER_TYPE_INTERRUPT
    return self
end


function usb_transfer.control(dev_hnd, bRequestType, bRequest, wValue, wIndex, data, wLength, timeout)
    return core.libusb_control_transfer(dev_hnd, bRequestType, bRequest, wValue, wIndex, data, wLength, timeout)
end

function usb_transfer.bulk(dev_hnd, endpoint, data, lenght, actual_length, timeout)
    return core.libusb_bulk_transfer(dev_hnd, endpoint, data, lenght, actual_length, timeout)
end

function usb_transfer.interrupt(dev_hnd, endpoint, data, lenght, actual_length, timeout)
    return core.libusb_interrupt_transfer(dev_hnd, endpoint, data, lenght, actual_length, timeout)
end

return usb_transfer