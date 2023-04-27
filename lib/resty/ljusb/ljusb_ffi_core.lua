local ffi = require'ffi'

--calling convention is auto-detected by LuaJIT except for callbacks
ffi.cdef((string.gsub([[
typedef void (LIBUSB_CALL *libusb_pollfd_added_cb)(int fd, short events,
  void *user_data);
typedef void (LIBUSB_CALL *libusb_pollfd_removed_cb)(int fd, void *user_data);

struct libusb_transfer;
typedef void (LIBUSB_CALL *libusb_transfer_cb_fn)(struct libusb_transfer *transfer);

struct libusb_device;
struct libusb_context;
typedef enum {
	LIBUSB_HOTPLUG_EVENT_DEVICE_ARRIVED = 0x01,
	LIBUSB_HOTPLUG_EVENT_DEVICE_LEFT    = 0x02,
} libusb_hotplug_event;
typedef int (LIBUSB_CALL *libusb_hotplug_callback_fn)(struct libusb_context *ctx,
						struct libusb_device *device,
						libusb_hotplug_event event,
						void *user_data);



typedef void (LIBUSB_CALL *libusb_log_cb)(struct libusb_context *ctx,
 	 enum libusb_log_level level, const char *str);

void LIBUSB_CALL libusb_set_log_cb(struct libusb_context *ctx, libusb_log_cb cb, int mode);

]], 'LIBUSB_CALL', jit.os == 'Windows' and '__stdcall' or '')))



ffi.cdef([[
typedef struct timeval {
  long tv_sec;
  long tv_usec;
} timeval;

typedef intptr_t ssize_t;
static const int LIBUSB_API_VERSION = 0x01000103;

enum libusb_class_code {
	LIBUSB_CLASS_PER_INTERFACE = 0,
	LIBUSB_CLASS_AUDIO = 1,
	LIBUSB_CLASS_COMM = 2,
	LIBUSB_CLASS_HID = 3,
	LIBUSB_CLASS_PHYSICAL = 5,
	LIBUSB_CLASS_PRINTER = 7,
	LIBUSB_CLASS_PTP = 6,
	LIBUSB_CLASS_IMAGE = 6,
	LIBUSB_CLASS_MASS_STORAGE = 8,
	LIBUSB_CLASS_HUB = 9,
	LIBUSB_CLASS_DATA = 10,
	LIBUSB_CLASS_SMART_CARD = 0x0b,
	LIBUSB_CLASS_CONTENT_SECURITY = 0x0d,
	LIBUSB_CLASS_VIDEO = 0x0e,
	LIBUSB_CLASS_PERSONAL_HEALTHCARE = 0x0f,
	LIBUSB_CLASS_DIAGNOSTIC_DEVICE = 0xdc,
	LIBUSB_CLASS_WIRELESS = 0xe0,
	LIBUSB_CLASS_APPLICATION = 0xfe,
	LIBUSB_CLASS_VENDOR_SPEC = 0xff
};

enum libusb_descriptor_type {
	LIBUSB_DT_DEVICE = 0x01,
	LIBUSB_DT_CONFIG = 0x02,
	LIBUSB_DT_STRING = 0x03,
	LIBUSB_DT_INTERFACE = 0x04,
	LIBUSB_DT_ENDPOINT = 0x05,
	LIBUSB_DT_BOS = 0x0f,
	LIBUSB_DT_DEVICE_CAPABILITY = 0x10,
	LIBUSB_DT_HID = 0x21,
	LIBUSB_DT_REPORT = 0x22,
	LIBUSB_DT_PHYSICAL = 0x23,
	LIBUSB_DT_HUB = 0x29,
	LIBUSB_DT_SUPERSPEED_HUB = 0x2a,
	LIBUSB_DT_SS_ENDPOINT_COMPANION = 0x30
};

static const int LIBUSB_DT_DEVICE_SIZE = 18;
static const int LIBUSB_DT_CONFIG_SIZE = 9;
static const int LIBUSB_DT_INTERFACE_SIZE = 9;
static const int LIBUSB_DT_ENDPOINT_SIZE = 7;
static const int LIBUSB_DT_ENDPOINT_AUDIO_SIZE = 9;
static const int LIBUSB_DT_HUB_NONVAR_SIZE = 7;
static const int LIBUSB_DT_SS_ENDPOINT_COMPANION_SIZE = 6;
static const int LIBUSB_DT_BOS_SIZE = 5;
static const int LIBUSB_DT_DEVICE_CAPABILITY_SIZE = 3;
static const int LIBUSB_BT_USB_2_0_EXTENSION_SIZE = 7;
static const int LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE = 10;
static const int LIBUSB_BT_CONTAINER_ID_SIZE = 20;

static const int  LIBUSB_DT_BOS_MAX_SIZE = LIBUSB_DT_BOS_SIZE +
    LIBUSB_BT_USB_2_0_EXTENSION_SIZE +
    LIBUSB_BT_SS_USB_DEVICE_CAPABILITY_SIZE +
    LIBUSB_BT_CONTAINER_ID_SIZE;

static const int LIBUSB_ENDPOINT_ADDRESS_MASK = 0x0f;
static const int LIBUSB_ENDPOINT_DIR_MASK = 0x80;
enum libusb_endpoint_direction {
	LIBUSB_ENDPOINT_IN = 0x80,
	LIBUSB_ENDPOINT_OUT = 0x00
};

static const int LIBUSB_TRANSFER_TYPE_MASK = 0x03;
enum libusb_transfer_type {
	LIBUSB_TRANSFER_TYPE_CONTROL = 0,
	LIBUSB_TRANSFER_TYPE_ISOCHRONOUS = 1,
	LIBUSB_TRANSFER_TYPE_BULK = 2,
	LIBUSB_TRANSFER_TYPE_INTERRUPT = 3,
	LIBUSB_TRANSFER_TYPE_BULK_STREAM = 4,
};
enum libusb_standard_request {
	LIBUSB_REQUEST_GET_STATUS = 0x00,
	LIBUSB_REQUEST_CLEAR_FEATURE = 0x01,
	LIBUSB_REQUEST_SET_FEATURE = 0x03,
	LIBUSB_REQUEST_SET_ADDRESS = 0x05,
	LIBUSB_REQUEST_GET_DESCRIPTOR = 0x06,
	LIBUSB_REQUEST_SET_DESCRIPTOR = 0x07,
	LIBUSB_REQUEST_GET_CONFIGURATION = 0x08,
	LIBUSB_REQUEST_SET_CONFIGURATION = 0x09,
	LIBUSB_REQUEST_GET_INTERFACE = 0x0A,
	LIBUSB_REQUEST_SET_INTERFACE = 0x0B,
	LIBUSB_REQUEST_SYNCH_FRAME = 0x0C,
	LIBUSB_REQUEST_SET_SEL = 0x30,
	LIBUSB_SET_ISOCH_DELAY = 0x31,
};
enum libusb_request_type {
	LIBUSB_REQUEST_TYPE_STANDARD = (0x00 << 5),
	LIBUSB_REQUEST_TYPE_CLASS = (0x01 << 5),
	LIBUSB_REQUEST_TYPE_VENDOR = (0x02 << 5),
	LIBUSB_REQUEST_TYPE_RESERVED = (0x03 << 5)
};
enum libusb_request_recipient {
	LIBUSB_RECIPIENT_DEVICE = 0x00,
	LIBUSB_RECIPIENT_INTERFACE = 0x01,
	LIBUSB_RECIPIENT_ENDPOINT = 0x02,
	LIBUSB_RECIPIENT_OTHER = 0x03,
};

static const int LIBUSB_ISO_SYNC_TYPE_MASK = 0x0C;
enum libusb_iso_sync_type {
	LIBUSB_ISO_SYNC_TYPE_NONE = 0,
	LIBUSB_ISO_SYNC_TYPE_ASYNC = 1,
	LIBUSB_ISO_SYNC_TYPE_ADAPTIVE = 2,
	LIBUSB_ISO_SYNC_TYPE_SYNC = 3
};

static const int LIBUSB_ISO_USAGE_TYPE_MASK = 0x30;
enum libusb_iso_usage_type {
	LIBUSB_ISO_USAGE_TYPE_DATA = 0,
	LIBUSB_ISO_USAGE_TYPE_FEEDBACK = 1,
	LIBUSB_ISO_USAGE_TYPE_IMPLICIT = 2,
};
struct libusb_device_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t bcdUSB;
	uint8_t  bDeviceClass;
	uint8_t  bDeviceSubClass;
	uint8_t  bDeviceProtocol;
	uint8_t  bMaxPacketSize0;
	uint16_t idVendor;
	uint16_t idProduct;
	uint16_t bcdDevice;
	uint8_t  iManufacturer;
	uint8_t  iProduct;
	uint8_t  iSerialNumber;
	uint8_t  bNumConfigurations;
};
struct libusb_endpoint_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bEndpointAddress;
	uint8_t  bmAttributes;
	uint16_t wMaxPacketSize;
	uint8_t  bInterval;
	uint8_t  bRefresh;
	uint8_t  bSynchAddress;
	const unsigned char *extra;
	int extra_length;
};
struct libusb_interface_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bInterfaceNumber;
	uint8_t  bAlternateSetting;
	uint8_t  bNumEndpoints;
	uint8_t  bInterfaceClass;
	uint8_t  bInterfaceSubClass;
	uint8_t  bInterfaceProtocol;
	uint8_t  iInterface;
	const struct libusb_endpoint_descriptor *endpoint;
	const unsigned char *extra;
	int extra_length;
};
struct libusb_interface {
	const struct libusb_interface_descriptor *altsetting;
	int num_altsetting;
};
struct libusb_config_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t wTotalLength;
	uint8_t  bNumInterfaces;
	uint8_t  bConfigurationValue;
	uint8_t  iConfiguration;
	uint8_t  bmAttributes;
	uint8_t  MaxPower;
	const struct libusb_interface *interface;
	const unsigned char *extra;
	int extra_length;
};
struct libusb_ss_endpoint_companion_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bMaxBurst;
	uint8_t  bmAttributes;
	uint16_t wBytesPerInterval;
};
struct libusb_bos_dev_capability_descriptor {
	uint8_t bLength;
	uint8_t bDescriptorType;
	uint8_t bDevCapabilityType;
	uint8_t dev_capability_data[];
};
struct libusb_bos_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint16_t wTotalLength;
	uint8_t  bNumDeviceCaps;
	struct libusb_bos_dev_capability_descriptor *dev_capability[];
};
struct libusb_usb_2_0_extension_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint32_t  bmAttributes;
};
struct libusb_ss_usb_device_capability_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t  bmAttributes;
	uint16_t wSpeedSupported;
	uint8_t  bFunctionalitySupport;
	uint8_t  bU1DevExitLat;
	uint16_t bU2DevExitLat;
};
struct libusb_container_id_descriptor {
	uint8_t  bLength;
	uint8_t  bDescriptorType;
	uint8_t  bDevCapabilityType;
	uint8_t bReserved;
	uint8_t  ContainerID[16];
};
struct libusb_control_setup {
	uint8_t  bmRequestType;
	uint8_t  bRequest;
	uint16_t wValue;
	uint16_t wIndex;
	uint16_t wLength;
};

static const int LIBUSB_CONTROL_SETUP_SIZE = sizeof(struct libusb_control_setup);

struct libusb_device;
struct libusb_device_handle;
struct libusb_hotplug_callback;
struct libusb_version {
	const uint16_t major;
	const uint16_t minor;
	const uint16_t micro;
	const uint16_t nano;
	const char *rc;
	const char* describe;
};
typedef struct libusb_context libusb_context;
typedef struct libusb_device libusb_device;
typedef struct libusb_device_handle libusb_device_handle;
enum libusb_speed {
	LIBUSB_SPEED_UNKNOWN = 0,
	LIBUSB_SPEED_LOW = 1,
	LIBUSB_SPEED_FULL = 2,
	LIBUSB_SPEED_HIGH = 3,
	LIBUSB_SPEED_SUPER = 4,
};
enum libusb_supported_speed {
	LIBUSB_LOW_SPEED_OPERATION   = 1,
	LIBUSB_FULL_SPEED_OPERATION  = 2,
	LIBUSB_HIGH_SPEED_OPERATION  = 4,
	LIBUSB_SUPER_SPEED_OPERATION = 8,
};
enum libusb_usb_2_0_extension_attributes {
	LIBUSB_BM_LPM_SUPPORT = 2,
};
enum libusb_ss_usb_device_capability_attributes {
	LIBUSB_BM_LTM_SUPPORT = 2,
};
enum libusb_bos_type {
	LIBUSB_BT_WIRELESS_USB_DEVICE_CAPABILITY	= 1,
	LIBUSB_BT_USB_2_0_EXTENSION			= 2,
	LIBUSB_BT_SS_USB_DEVICE_CAPABILITY		= 3,
	LIBUSB_BT_CONTAINER_ID				= 4,
};
enum libusb_error {
	LIBUSB_SUCCESS = 0,
	LIBUSB_ERROR_IO = -1,
	LIBUSB_ERROR_INVALID_PARAM = -2,
	LIBUSB_ERROR_ACCESS = -3,
	LIBUSB_ERROR_NO_DEVICE = -4,
	LIBUSB_ERROR_NOT_FOUND = -5,
	LIBUSB_ERROR_BUSY = -6,
	LIBUSB_ERROR_TIMEOUT = -7,
	LIBUSB_ERROR_OVERFLOW = -8,
	LIBUSB_ERROR_PIPE = -9,
	LIBUSB_ERROR_INTERRUPTED = -10,
	LIBUSB_ERROR_NO_MEM = -11,
	LIBUSB_ERROR_NOT_SUPPORTED = -12,
	LIBUSB_ERROR_OTHER = -99,
};
static const int LIBUSB_ERROR_COUNT = 14;
enum libusb_transfer_status {
	LIBUSB_TRANSFER_COMPLETED,
	LIBUSB_TRANSFER_ERROR,
	LIBUSB_TRANSFER_TIMED_OUT,
	LIBUSB_TRANSFER_CANCELLED,
	LIBUSB_TRANSFER_STALL,
	LIBUSB_TRANSFER_NO_DEVICE,
	LIBUSB_TRANSFER_OVERFLOW,
};
enum libusb_transfer_flags {
	LIBUSB_TRANSFER_SHORT_NOT_OK = 1<<0,
	LIBUSB_TRANSFER_FREE_BUFFER = 1<<1,
	LIBUSB_TRANSFER_FREE_TRANSFER = 1<<2,
	LIBUSB_TRANSFER_ADD_ZERO_PACKET = 1 << 3,
};
struct libusb_iso_packet_descriptor {
	unsigned int length;
	unsigned int actual_length;
	enum libusb_transfer_status status;
};

struct libusb_transfer {
	libusb_device_handle *dev_handle;
	uint8_t flags;
	unsigned char endpoint;
	unsigned char type;
	unsigned int timeout;
	enum libusb_transfer_status status;
	int length;
	int actual_length;
	libusb_transfer_cb_fn callback;
	void *user_data;
	unsigned char *buffer;
	int num_iso_packets;
	struct libusb_iso_packet_descriptor iso_packet_desc[];
};
enum libusb_capability {
	LIBUSB_CAP_HAS_CAPABILITY = 0x0000,
	LIBUSB_CAP_HAS_HOTPLUG = 0x0001,
	LIBUSB_CAP_HAS_HID_ACCESS = 0x0100,
	LIBUSB_CAP_SUPPORTS_DETACH_KERNEL_DRIVER = 0x0101
};
enum libusb_log_level {
	LIBUSB_LOG_LEVEL_NONE = 0,
	LIBUSB_LOG_LEVEL_ERROR,
	LIBUSB_LOG_LEVEL_WARNING,
	LIBUSB_LOG_LEVEL_INFO,
	LIBUSB_LOG_LEVEL_DEBUG,
};

int libusb_init(libusb_context **ctx);
void libusb_exit(libusb_context *ctx);
void  libusb_set_debug(libusb_context *ctx, int level);
const struct libusb_version * libusb_get_version(void);
int libusb_has_capability(uint32_t capability);
const char * libusb_error_name(int errcode);
int libusb_setlocale(const char *locale);
const char * libusb_strerror(enum libusb_error errcode);

ssize_t libusb_get_device_list(libusb_context *ctx,
	libusb_device ***list);
void libusb_free_device_list(libusb_device **list,
	int unref_devices);
libusb_device * libusb_ref_device(libusb_device *dev);
void libusb_unref_device(libusb_device *dev);

int libusb_get_configuration(libusb_device_handle *dev,
	int *config);
int libusb_get_device_descriptor(libusb_device *dev,
	struct libusb_device_descriptor *desc);
int libusb_get_active_config_descriptor(libusb_device *dev,
	struct libusb_config_descriptor **config);
int libusb_get_config_descriptor(libusb_device *dev,
	uint8_t config_index, struct libusb_config_descriptor **config);
int libusb_get_config_descriptor_by_value(libusb_device *dev,
	uint8_t bConfigurationValue, struct libusb_config_descriptor **config);
void libusb_free_config_descriptor(
	struct libusb_config_descriptor *config);
int libusb_get_ss_endpoint_companion_descriptor(
	struct libusb_context *ctx,
	const struct libusb_endpoint_descriptor *endpoint,
	struct libusb_ss_endpoint_companion_descriptor **ep_comp);
void libusb_free_ss_endpoint_companion_descriptor(
	struct libusb_ss_endpoint_companion_descriptor *ep_comp);
int libusb_get_bos_descriptor(libusb_device_handle *handle,
	struct libusb_bos_descriptor **bos);
void libusb_free_bos_descriptor(struct libusb_bos_descriptor *bos);
int libusb_get_usb_2_0_extension_descriptor(
	struct libusb_context *ctx,
	struct libusb_bos_dev_capability_descriptor *dev_cap,
	struct libusb_usb_2_0_extension_descriptor **usb_2_0_extension);
void libusb_free_usb_2_0_extension_descriptor(
	struct libusb_usb_2_0_extension_descriptor *usb_2_0_extension);
int libusb_get_ss_usb_device_capability_descriptor(
	struct libusb_context *ctx,
	struct libusb_bos_dev_capability_descriptor *dev_cap,
	struct libusb_ss_usb_device_capability_descriptor **ss_usb_device_cap);
void libusb_free_ss_usb_device_capability_descriptor(
	struct libusb_ss_usb_device_capability_descriptor *ss_usb_device_cap);
int libusb_get_container_id_descriptor(struct libusb_context *ctx,
	struct libusb_bos_dev_capability_descriptor *dev_cap,
	struct libusb_container_id_descriptor **container_id);
void libusb_free_container_id_descriptor(
	struct libusb_container_id_descriptor *container_id);
uint8_t libusb_get_bus_number(libusb_device *dev);
uint8_t libusb_get_port_number(libusb_device *dev);
int libusb_get_port_numbers(libusb_device *dev, uint8_t* port_numbers, int port_numbers_len);
libusb_device * libusb_get_parent(libusb_device *dev);
uint8_t libusb_get_device_address(libusb_device *dev);
int libusb_get_device_speed(libusb_device *dev);
int libusb_get_max_packet_size(libusb_device *dev,
	unsigned char endpoint);
int libusb_get_max_iso_packet_size(libusb_device *dev,
	unsigned char endpoint);

int libusb_open(libusb_device *dev, libusb_device_handle **handle);
void libusb_close(libusb_device_handle *dev_handle);
libusb_device * libusb_get_device(libusb_device_handle *dev_handle);

int libusb_set_configuration(libusb_device_handle *dev,
	int configuration);
int libusb_claim_interface(libusb_device_handle *dev,
	int interface_number);
int libusb_release_interface(libusb_device_handle *dev,
	int interface_number);

libusb_device_handle * libusb_open_device_with_vid_pid(
	libusb_context *ctx, uint16_t vendor_id, uint16_t product_id);

int libusb_set_interface_alt_setting(libusb_device_handle *dev,
	int interface_number, int alternate_setting);
int libusb_clear_halt(libusb_device_handle *dev,
	unsigned char endpoint);
int libusb_reset_device(libusb_device_handle *dev);

int libusb_alloc_streams(libusb_device_handle *dev,
	uint32_t num_streams, unsigned char *endpoints, int num_endpoints);
int libusb_free_streams(libusb_device_handle *dev,
	unsigned char *endpoints, int num_endpoints);

int libusb_kernel_driver_active(libusb_device_handle *dev,
	int interface_number);
int libusb_detach_kernel_driver(libusb_device_handle *dev,
	int interface_number);
int libusb_attach_kernel_driver(libusb_device_handle *dev,
	int interface_number);
int libusb_set_auto_detach_kernel_driver(
	libusb_device_handle *dev, int enable);

struct libusb_transfer * libusb_alloc_transfer(int iso_packets);
int libusb_submit_transfer(struct libusb_transfer *transfer);
int libusb_cancel_transfer(struct libusb_transfer *transfer);
void libusb_free_transfer(struct libusb_transfer *transfer);
void libusb_transfer_set_stream_id(
	struct libusb_transfer *transfer, uint32_t stream_id);
uint32_t libusb_transfer_get_stream_id(
	struct libusb_transfer *transfer);

int libusb_control_transfer(libusb_device_handle *dev_handle,
	uint8_t request_type, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	unsigned char *data, uint16_t wLength, unsigned int timeout);

int libusb_bulk_transfer(libusb_device_handle *dev_handle,
	unsigned char endpoint, unsigned char *data, int length,
	int *actual_length, unsigned int timeout);

int libusb_interrupt_transfer(libusb_device_handle *dev_handle,
	unsigned char endpoint, unsigned char *data, int length,
	int *actual_length, unsigned int timeout);

int libusb_get_string_descriptor_ascii(libusb_device_handle *dev,
	uint8_t desc_index, unsigned char *data, int length);

int libusb_try_lock_events(libusb_context *ctx);
void libusb_lock_events(libusb_context *ctx);
void libusb_unlock_events(libusb_context *ctx);
int libusb_event_handling_ok(libusb_context *ctx);
int libusb_event_handler_active(libusb_context *ctx);
void libusb_lock_event_waiters(libusb_context *ctx);
void libusb_unlock_event_waiters(libusb_context *ctx);
int libusb_wait_for_event(libusb_context *ctx, struct timeval *tv);

int libusb_handle_events_timeout(libusb_context *ctx,
	struct timeval *tv);
int libusb_handle_events_timeout_completed(libusb_context *ctx,
	struct timeval *tv, int *completed);
int libusb_handle_events(libusb_context *ctx);
int libusb_handle_events_completed(libusb_context *ctx, int *completed);
int libusb_handle_events_locked(libusb_context *ctx,
	struct timeval *tv);
int libusb_pollfds_handle_timeouts(libusb_context *ctx);
int libusb_get_next_timeout(libusb_context *ctx,
	struct timeval *tv);
struct libusb_pollfd {
	int fd;
	short events;
};

const struct libusb_pollfd ** libusb_get_pollfds(
	libusb_context *ctx);
void libusb_set_pollfd_notifiers(libusb_context *ctx,
	libusb_pollfd_added_cb added_cb, libusb_pollfd_removed_cb removed_cb,
	void *user_data);
typedef int libusb_hotplug_callback_handle;
typedef enum {
	LIBUSB_HOTPLUG_ENUMERATE = 1,
} libusb_hotplug_flag;
static const int LIBUSB_HOTPLUG_MATCH_ANY = -1;
int libusb_hotplug_register_callback(libusb_context *ctx,
						libusb_hotplug_event events,
						libusb_hotplug_flag flags,
						int vendor_id, int product_id,
						int dev_class,
						libusb_hotplug_callback_fn cb_fn,
						void *user_data,
						libusb_hotplug_callback_handle *handle);
void libusb_hotplug_deregister_callback(libusb_context *ctx,
						libusb_hotplug_callback_handle handle);
]])

ffi.cdef(
[[

static inline void libusb_fill_bulk_transfer(struct libusb_transfer *transfer,
	libusb_device_handle *dev_handle, unsigned char endpoint,
	unsigned char *buffer, int length, libusb_transfer_cb_fn callback,
	void *user_data, unsigned int timeout);

static inline void libusb_fill_bulk_stream_transfer(
	struct libusb_transfer *transfer, libusb_device_handle *dev_handle,
	unsigned char endpoint, uint32_t stream_id,
	unsigned char *buffer, int length, libusb_transfer_cb_fn callback,
	void *user_data, unsigned int timeout);

static inline void libusb_fill_interrupt_transfer(
	struct libusb_transfer *transfer, libusb_device_handle *dev_handle,
	unsigned char endpoint, unsigned char *buffer, int length,
	libusb_transfer_cb_fn callback, void *user_data, unsigned int timeout);

static inline void libusb_fill_iso_transfer(struct libusb_transfer *transfer,
	libusb_device_handle *dev_handle, unsigned char endpoint,
	unsigned char *buffer, int length, int num_iso_packets,
	libusb_transfer_cb_fn callback, void *user_data, unsigned int timeout);

static inline void libusb_set_iso_packet_lengths(
	struct libusb_transfer *transfer, unsigned int length);


static inline unsigned char *libusb_get_iso_packet_buffer(
	struct libusb_transfer *transfer, unsigned int packet);


static inline unsigned char *libusb_get_iso_packet_buffer_simple(
	struct libusb_transfer *transfer, unsigned int packet);


static inline unsigned char *libusb_control_transfer_get_data(
	struct libusb_transfer *transfer);


static inline struct libusb_control_setup *libusb_control_transfer_get_setup(
	struct libusb_transfer *transfer);


static inline void libusb_fill_control_setup(unsigned char *buffer,
	uint8_t bmRequestType, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

static inline int libusb_get_descriptor(libusb_device_handle *dev,
	uint8_t desc_type, uint8_t desc_index, unsigned char *data, int length);

static inline int libusb_get_string_descriptor(libusb_device_handle *dev,
	uint8_t desc_index, uint16_t langid, unsigned char *data, int length);

]])

local suffix

    if ffi.os == "OSX" then
        suffix = ".dylib"
    elseif ffi.os == "Windows" then
        suffix = ".dll"
    else
        suffix = ".so"
    end
local libname = 'libusb' .. suffix

local lib = ffi.load(libname)
--local s, lib = pcall(ffi.load, libname )
--fallback: assume libusb statically linked into our executable (=> accessible via ffi.C)
--assert(s, "load error " .. libname)

--lib = s and lib or ffi.C

local function getversion()
  local v = lib.libusb_get_version()
  return v.major, v.minor, v.micro, v.nano
end

local st, major = pcall(getversion)

assert(st, "libusb_get_version call failed (make sure libusb-1.0 is present and visible to Lua)")
assert(major == 1, "libusb version mismatch (need libusb-1.x.x)")

return lib
