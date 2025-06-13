const std = @import("std");
const wdocs = @import("wdocs");

pub fn main() !void {
    const slice = "hello-world, or something else__ + 01234";
    var idx: usize = 0;

    while (idx != slice.len) {
        const word = wdocs.collectWord(slice, &idx);

        // if no match, skip character
        if (word.len == 0) {
            idx += 1;
            continue;
        }
        
        std.debug.print("word: {s}\n", .{word});
    }
}
