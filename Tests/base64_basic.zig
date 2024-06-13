const std = @import("std");
const stdout = std.io.getStdOut().writer();

fn print(input: []const u8) !void {
    try stdout.print("{s}\n", .{input});
}

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers,
        };
    }

    fn _char_at(self: Base64, index: u8) u8 {
        return self._table[index];
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=')
            return 64;

        var index: u8 = 0;
        for (0..63) |_| {
            if (self._char_at(index) == char)
                break;
            index += 1;
        }

        return index;
    }

    fn encode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]u8 {
        if (input.len == 0)
            return "";

        const n_output = _calc_encode_length(input);
        var output = try allocator.alloc(u8, n_output);
        var tmp_buffer = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var output_index: u64 = 0;

        for (input, 0..) |_, i| {
            tmp_buffer[count] = input[i];
            count += 1;
            if (count == 3) {
                output[output_index] = self._char_at(tmp_buffer[0] >> 2);
                output[output_index + 1] = self._char_at(((tmp_buffer[0] & 0x03) << 4) + (tmp_buffer[1] >> 4));
                output[output_index + 2] = self._char_at(((tmp_buffer[1] & 0x0f) << 2) + (tmp_buffer[2] >> 6));
                output[output_index + 3] = self._char_at(tmp_buffer[2] & 0x3f);
                output_index += 4;
                count = 0;
            }
        }

        if (count == 1) {
            output[output_index] = self._char_at(tmp_buffer[0] >> 2);
            output[output_index + 1] = self._char_at((tmp_buffer[0] & 0x03) << 4);
            output[output_index + 2] = '=';
            output[output_index + 3] = '=';
        }

        if (count == 2) {
            output[output_index] = self._char_at(tmp_buffer[0] >> 2);
            output[output_index + 1] = self._char_at(((tmp_buffer[0] & 0x03) << 4) + (tmp_buffer[1] >> 4));
            output[output_index + 2] = self._char_at((tmp_buffer[1] & 0x0f) << 2);
            output[output_index + 3] = '=';
            output_index += 4;
        }

        return output;
    }

    fn decode(self: Base64, input: []const u8, allocator: std.mem.Allocator) ![]u8 {
        if (input.len == 0)
            return "";

        const n_output = _calc_decode_length(input);
        var tmp_buffer = [4]u8{ 0, 0, 0, 0 };
        var output = try allocator.alloc(u8, n_output);
        var count: u8 = 0;
        var output_index: u64 = 0;

        for (output, 0..) |_, i| {
            output[i] = 0;
        }

        for (input, 0..) |_, i| {
            const index: u8 = @intCast(i);
            tmp_buffer[count] = self._char_index(input[index]);
            count += 1;
            if (count == 4) {
                output[output_index] = (tmp_buffer[0] << 2) + (tmp_buffer[1] >> 4);
                if (tmp_buffer[2] != 64) {
                    output[output_index + 1] = (tmp_buffer[1] << 4) + (tmp_buffer[2] >> 2);
                }
                if (tmp_buffer[3] != 64) {
                    output[output_index + 2] = (tmp_buffer[2] << 6) + tmp_buffer[3];
                }
                output_index += 3;
                count = 0;
            }
        }

        return output;
    }
};

fn _calc_encode_length(input: []const u8) u64 {
    const len_as_float: f64 = @floatFromInt(input.len);
    if (input.len < 3) {
        const n_output: u64 = 4;
        return n_output;
    }

    const n_output: u64 = @intFromFloat(@ceil(len_as_float / 3.0) * 4.0);
    return n_output;
}

fn _calc_decode_length(input: []const u8) u64 {
    const len_as_float: f64 = @floatFromInt(input.len);
    if (input.len < 4) {
        const n_output: u64 = 3;
        return n_output;
    }
    const n_output: u64 = @intFromFloat(@floor(len_as_float / 4.0) * 3.0);
    return n_output;
}

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const text = "Testing some more shit";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc2hpdA==";
    const base64 = Base64.init();
    const encoded_text = try base64.encode(text, allocator);
    const decoded_text = try base64.decode(etext, allocator);
    try stdout.print("Encoded text: {s}\n", .{encoded_text});
    try stdout.print("Decoded text: {s}\n", .{decoded_text});
}
