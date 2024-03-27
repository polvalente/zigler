const beam = @import("beam.zig");
const e = @import("erl_nif");
const options = @import("options.zig");
const threads = @import("threads.zig");

const PidError = error{ NotProcessBound, NotDelivered };

pub fn self(opts: anytype) PidError!beam.pid {
    var pid: beam.pid = undefined;
    switch (beam.context.mode) {
        .threaded => {
            return threads.self_pid();
        },
        .callback => {
            return error.NotProcessBound;
        },
        else => {
            if (e.enif_self(options.env(opts), &pid)) |_| {
                return pid;
            } else {
                return error.NotProcessBound;
            }
        },
    }
}

pub fn send(dest: beam.pid, content: anytype, opts: anytype) PidError!beam.term {
    beam.ignore_when_sema();

    const term = beam.make(content, opts);

    // enif_send is not const-correct so we have to assign a variable to the static
    // pid variable

    var pid = dest;
    // disable this in sema because pid pointers are not supported

    switch (beam.context.mode) {
        .synchronous, .callback, .dirty => {
            if (e.enif_send(options.env(opts), &pid, null, term.v) == 0) return error.NotDelivered;
        },
        .threaded, .yielding, .dirty_yield => {
            defer {
                if (options.should_clear(opts)) {
                    beam.clear_env(options.env(opts));
                }
            }

            if (e.enif_send(null, &pid, options.env(opts), term.v) == 0) return error.NotDelivered;
        },
    }
    return term;
}
