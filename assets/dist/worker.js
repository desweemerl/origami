var W = (function () {
    'use strict';

    // 

    function isObject(value) {
        return typeof value === "object" && value !== null && value.constructor === Object;
    }

    function isNumber(value) {
        return typeof value === "number" && !Number.isNaN(value) && Number.isFinite(value);
    }

    var types = {
        isObject,
        isNumber,
    };

    // 

    function checkDataAndIndex(data, index) {
        if (!Array.isArray(data)) {
            throw new Error("data must be an Array");
        }

        if (!isNumber(index)) {
            throw new Error("index must be a Number");
        }

        return true;
    }

    function updateAt(data, index, value) {
        return checkDataAndIndex(data, index) && index >= 0 && index < data.length
            ? data.slice(0, index).concat(value).concat(data.slice(index))
            : data;
    }

    function at(data, index, defaultValue = null) {
        return checkDataAndIndex(data, index) && index >= 0 && index < data.length
            ? data[index]
            : defaultValue;
    }

    var array = {
        updateAt,
        at,
    };

    // 

    function checkDataAndKey(data, key) {
        if (!isObject(data)) {
            throw new Error("data must be an Object");
        }

        if (typeof key !== "string") {
            throw new Error("key must be a string");
        }

        return true;
    }

    function get(data, key, defaultValue = null) {
        return checkDataAndKey(data, key) && (key in data) ? data[key] : defaultValue;
    }

    function put(data, key, value) {
        return checkDataAndKey(data, key) && {...data, [key]: value};
    }

    var dict = {
        get,
        put,
    };

    // 

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

    var logger = {
        logFactory,
        log: logFactory(),
        error: logFactory(console.error, true),
        debug: logFactory(console.debug, true),
    };

    // 

    function pipe() {
        const fns = arguments;

        return function _pipe(value) {
            let result = value;

            for (let i = 0; i < fns.length; i++) {
                result = fns[i](result);
            }

            return result;
        }
    }

    function matchObjects(a, b) {
        for (let k in b) {
            if (!(k in a) || !match(a[k], b[k])) {
                return false;
            }
        }

        return true;
    }

    function matchArrays(a, b) {
        if (a.length >= b.length) {
            for (let i = 0; i < b.length; i++) {
                if (!match(a[i], b[i])) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    function match(a, b) {
        if (b === "*") {
            return true;
        }

        if (
            (typeof a === "string" && typeof b === "string") ||
            (isNumber(a) && isNumber(b))
        ) {
            return a === b;
        }

        if (isObject(a) && isObject(b)) {
            return matchObjects(a, b);
        }

        if (Array.isArray(a) && Array.isArray(b)) {
            return matchArrays(a, b);
        }

        return false;
    }

    function matchFn(b, callback) {
        return function _matchFn(a) {
            if (match(a, b)) {
                callback(a);
                return true;
            }

            return false;
        }
    }

    var fns = {
        pipe,
        match,
        matchFn,
    };

    // 


    function getValueOnPath(data, key, path) {
        if (typeof key === "undefined") {
            return data;
        }

        let value;

        if (isObject(data)) {
            value = dict.get(data, key);
        } else if (Array.isArray(data)) {
            value = array.at(data, key);
        } else {
            throw new Error("data is not an Array or an Object");
        }

        return (!path || !path.length)
            ? value : getValueOnPath(value, path[0], path.slice(1));
    }

    function setValueOnPath(data, value, key, path) {
        if (typeof key === "undefined") {
            throw new Error("key is missing");
        }

        if (!path || !path.length) {
            if (isObject(data)) {
                if (typeof key !== "string") {
                    throw new Error("key must be a string");
                }
            } else if (Array.isArray(data)) {
                if (!isNumber(key)) {
                    throw new Error("index must be a Number");
                }
            } else {
                throw new Error("data is not an Array or an Object");
            }

            data[key] = value;
        } else {
            let nextData;

            if (isObject(data)) {
                nextData = dict.get(data, key);
            } else if (Array.isArray(data)) {
                nextData = array.at(data, key);
            }

            if (nextData === null) {
                if (typeof path[0] === "number") {
                    nextData = [];
                } else {
                    nextData = {};
                }

                data[key] = nextData;
            }

            setValueOnPath(nextData, value, path[0], path.slice(1));
        }
    }

    function mergeTouchedPaths(currentPaths, path) {
        let found = false;
        let insert = false;

        const nextPaths = currentPaths
            .filter(function _checkPath(currentPath) {
                let count = 0;

                for (let i = 0; i < Math.min(currentPath.length, path.length); i++) {
                    if (currentPath[i] === path[i]) {
                        found = true;
                        count++;
                    }
                }

                if (count === path.length && path.length < currentPath.length) {
                    insert = true;
                    return false;
                }

                return true;
            });

        return insert || !found ? nextPaths.concat([path]) : nextPaths;
    }

    function storeFactory(data, onTouchedPathChange) {
        if (typeof data === "undefined") {
            data = {};
        } else if (!isObject(data) && !Array.isArray(data)) {
            throw new Error("store must be an Array or an Object");
        }

        let touchedPaths = [];

        function getValue(path) {
            const pathArray = Array.isArray(path) ? path : [path];
            return getValueOnPath(data, pathArray[0], pathArray.slice(1));
        }

        function setValue(value, path) {
            const pathArray = Array.isArray(path) ? path : [path];
            setValueOnPath(data, value, pathArray[0], pathArray.slice(1));
            touchedPaths = mergeTouchedPaths(touchedPaths, pathArray);

            if (typeof onTouchedPathChange === "function") {
                onTouchedPathChange(touchedPaths);
            }

            return data;
        }

        function markAsUntouched() {
            touchedPaths.length = 0;

            if (typeof onTouchedPathChange === "function") {
                onTouchedPathChange(touchedPaths);
            }
        }

        function getTouchedPaths() {
            return touchedPaths;
        }

        function clear() {
            data = {};
            touchedPaths.length = 0;
        }

        return {
            get: getValue,
            set: setValue,
            clear,
            markAsUntouched,
            getTouchedPaths,
            restrict: {
                get: getValue,
                set: setValue,
            }
        }
    }

    // 

    function receiversFactory(receivers) {
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

    // 


    var core = {
        ...types,
        ...array,
        ...dict,
        ...fns,
        receiversFactory,
        storeFactory,
        logger,
    };

    // 

    let id, alias;

    const workerReceivers = receiversFactory();

    function send(message) {
        postMessage(message);
    }

    onmessage = function _onMessage(event) {
        workerReceivers.sendToReceivers(event.data);
    };

    const initReceiver = matchFn({action: "init"}, function _initReceiver(message) {
        if (!isNumber(message.id)) {
            throw new Error(`wrong id ${message.id}`);
        }

        id = message.id;

        if (typeof message.alias === "string") {
            alias = message.alias;
        }

        send({action: "initAck", id, alias});
    });

    workerReceivers.receive(initReceiver);

    var worker = {
        ...core,
        ...workerReceivers,
        send,
    };

    return worker;

}());
//# sourceMappingURL=worker.js.map
