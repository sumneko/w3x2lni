require "i18n"

local cm = i18n.conv_method((2 << 16) | string.byte("?", 1))

function utf8_to_ansi(str)
	return i18n.utf8_to_ansi(str, cm)
end

function ansi_to_utf8(str)
	return i18n.ansi_to_utf8(str, cm)
end

local real_io_open = io.open

function io.open(path, ...)
	return real_io_open(utf8_to_ansi(path), ...)
end