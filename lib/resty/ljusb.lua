local ffi = require'ffi'
local bit = require'bit'
local core = require'ljusb.core'

local bor, band, lshift, rshift = bit.bor, bit.band, bit.lshift, bit.rshift
local new, typeof, metatype = ffi.new, ffi.typeof, ffi.metatype
local cast, C = ffi.cast, ffi.C

--need those for buffer management
ffi.cdef[[
void * malloc (size_t size);
void * realloc (void *ptr, size_t size);
void * memmove (void *destination, const void *source, size_t num);
void free (void *ptr);
]]

local usb_context = require "ljusb.context"

local ctx_methods = {
  has_hotplug_capatibility = function(usb)
    return core.libusb_has_capability(usb, code.LIBUSB_CAP_HAS_HOTPLUG) > 0
  end,
}

return usb_context.__new()
