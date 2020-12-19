// @flow

export function receiversFactory(receivers) {
    if (typeof receivers === "undefined") {
        receivers = [];
    } else if (!Array.isArray(receivers)) {
        throw new Error("receivers must be an Array");
    }

    function sendToReceivers(message) {
        for (let i = 0; i < receivers.length; i++) {
            if (receivers[i](message)) {
                return true;
            }
        }

        return false;
    }

    function receive(callback) {
        if (receivers.indexOf(callback) !== -1) {
            throw new Error("callback already registered");
        }

        receivers.push(callback);

        return true;
    }

    function unreceive(callback) {
        const i = receivers.indexOf(callback);
        if (i === -1) {
            throw new Error("callback not registered");
        }

        receivers.splice(i, 1);

        return true;
    }

    function clear() {
        receivers.length = 0;
    }

    return {
        sendToReceivers,
        receive,
        unreceive,
        clear,
    }

}
