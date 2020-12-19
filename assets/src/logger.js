// @flow

function logFactory(logger = console.log, withTrace = false) {
    return function _logFactory(arg) {
        let logged = false;

        if (withTrace) {
            const stack = new Error().stack;
            const lines = stack.split("\n");

            if (lines.length > 2) {
                logger(arg, lines[2]);
                logged = true;
            }
        }
        !logged && logger(arg);

        return [arg];
    }
}

export default {
    logFactory,
    log: logFactory(),
    error: logFactory(console.error, true),
    debug: logFactory(console.debug, true),
}
