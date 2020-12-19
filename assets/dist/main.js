var W = (function () {
    'use strict';

    // 

    /**
     * Unit can be worker or component.
     */
    let id = 0; // ID counter
    const aliases = {};
    const units = {}; // Unit store

    const messageCbs = [];
    const registrationCbs = [];
    const unregistrationCbs = [];

    function seekCb(cbs) {
        return function _seekCallback(arg) {
            for (let i = 0; i < cbs.length; i++) {
                if (cbs[i](arg)) {
                    return true;
                }
            }

            return false;
        }
    }

    const seekMessageCbs = seekCb(messageCbs);
    const seekRegistrationCbs = seekCb(registrationCbs);
    const seekUnregistrationCbs = seekCb(unregistrationCbs);

    function pushCallback(callbacks) {
        return function _pushCallback() {
            for (let i = 0; i < arguments.length; i++) {
                const fn = arguments[i];

                if (typeof fn !== "function") {
                    throw new Error(`argument ${i} must be a function`);
                }

                callbacks.push(fn);
            }

            return true;
        }
    }

    const addMessageCbs = pushCallback(messageCbs);
    const addUnregistrationCbs = pushCallback(unregistrationCbs);

    function checkId(id) {
        if (!(id in units)) {
            throw new Error(`unit with id ${id} doesn't exist`);
        }

        return id;
    }

    function getIdFromAlias(alias) {
        if (!(alias in aliases)) {
            throw new Error(`alias ${idOrAlias} is not registered`);
        }

        return aliases[alias];
    }

    function getUnitId(idOrAlias) {
        return typeof idOrAlias === "string"
            ? getIdFromAlias(idOrAlias)
            : idOrAlias;
    }

    function checkAndGetUnit(id) {
        return units[checkId(id)];
    }

    function getUnit(idOrAlias) {
        const id = getUnitId(idOrAlias);

        return checkAndGetUnit(id);
    }

    function send(idOrAlias, message) {
        const id = getUnitId(idOrAlias);
        const unit = checkAndGetUnit(id);

        return seekMessageCbs({unit, message, id});
    }

    function registerUnit(unit, alias) {
        const unitId = id;

        if (alias) {
            if (typeof alias !== "string") {
                throw new Error("bad alias");
            }

            if (alias in aliases) {
                throw new Error(`alias ${alias} has been already registered`);
            }

            aliases[alias] = unitId;
        }

        seekRegistrationCbs({unit, id, alias});
        units[id++] = unit;

        return unitId;
    }

    function unregisterUnit(idOrAlias) {
        let id = idOrAlias;
        let alias = null;

        if (typeof idOrAlias === "string") {
            alias = idOrAlias;
            id = getIdFromAlias(alias);
            delete (aliases[alias]);
        }

        const unit = getUnit(id);
        seekUnregistrationCbs({unit, id, alias});

        delete (units[id]);

        return id;
    }

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

    const componentFlag = {};
    const componentTouchedIds = new Set();

    function checkTouchedPaths() {
        for (let id of componentTouchedIds) {
            const component = getUnit(parseFloat(id));

            component.render({
                store: component.store.restrict,
                nodes: component.nodes,
                parentNode: component.parentNode,
                send,
            });

            componentTouchedIds.delete(id);

            component.store.markAsUntouched();
        }
    }

    const componentWatcher = window.setInterval(checkTouchedPaths, 10);

    function processComponentMessage(unit, message) {
        if (isObject(unit) && unit.componentFlag === componentFlag) {
            unit.receivers.sendToReceivers(message);
            return true;
        }

        return false;
    }

    function processComponentUnregistration(unit) {
        if (isObject(unit) && unit.componentFlag === componentFlag) {
            unit.receivers.clear();
            unit.store.clear();
            detachComponentNodes(unit);

            return true;
        }

        return false;
    }

    function createComponent({js, render, alias, parentNode}) {
        let data = {};
        let id;

        const store = storeFactory(
            data,
            function _onTouchedPathChange(touchedPaths) {
                if (touchedPaths.length) {
                    componentTouchedIds.add(id);
                } else {
                    componentTouchedIds.delete(id);
                }
            });

        const receivers = receiversFactory();
        const nodes = [];
        const component = {
            store,
            receivers,
            render,
            nodes,
            componentFlag,
        };

        id = registerUnit(component, alias);

        js({
            store: store.restrict,
            receive: receivers.receive,
            unreceive: receivers.unreceive,
            send,
        });

        render({
            init: true,
            store: store.restrict,
            nodes,
            parentNode,
            send,
        });

        if (parentNode) {
            attachComponentNodes(component, parentNode);
        }

        return id;
    }

    function deleteComponent(idOrdAlias) {
        unregisterUnit(idOrdAlias);
    }

    function attachComponentNodes(component, parentNode) {
        if (component.parentNode) {
            throw new Error(`component is already attached to a parent node`);
        }

        for (let i = 0; i < component.nodes.length; i++) {
            parentNode.appendChild(component.nodes[i]);
        }

        component.parentNode = parentNode;

        return true;
    }

    function attachComponent(idOrAlias, parentNode) {
        return attachComponentNodes(getUnit(idOrAlias), parentNode);
    }

    function detachComponentNodes(component) {
        if (!component.parentNode) {
            throw new Error(`component has no parent node`);
        }

        for (let i = 0; i < component.nodes.length; i++) {
            component.parentNode.removeChild(component.nodes[i]);
        }

        component.parentNode = null;

        return true;
    }

    function detachComponent(idOrAlias) {
        return detachComponentNodes(getUnit(idOrAlias));
    }

    addMessageCbs(processComponentMessage);
    addUnregistrationCbs(processComponentUnregistration);

    // 

    const mainReceivers = receiversFactory();

    function createWorker(jsFile, alias) {
        return new Promise(
            function _createWorker(resolve, reject) {
                if (typeof jsFile !== "string" || !jsFile) {
                    return reject("bad jsFile");
                }

                const worker = new Worker(jsFile);
                const id = registerUnit(worker, alias);

                worker.onerror = function _onWorkerError(err) {
                    console.log(err);
                    //logger.debug(`Failed to create worker with js ${jsFile}`, err);
                    unregisterUnit(id);
                    reject(err);
                };

                worker.postMessage({
                    action: "init",
                    id: id,
                    alias,
                });

                let firstMessage = true;

                worker.onmessage = function _onWorkerMessage(event) {
                    logger.debug(`Receiving data from worker with id ${id}: ${JSON.stringify(event.data)}`);

                    if (firstMessage) {
                        firstMessage = false;
                        resolve({id, worker, alias});
                    }

                    mainReceivers.sendToReceivers(event.data);
                };
            }
        );
    }

    function deleteWorker(idOrAlias) {
        return unregisterUnit(idOrAlias);
    }

    function processWorkerMessage({unit, message}) {
        if (unit instanceof Worker) {
            unit.postMessage(message);

            return true;
        }

        return false;
    }

    function processWorkerUnregistration({unit}) {
        if (unit instanceof Worker) {
            unit.terminate();

            return true;
        }

        return false;
    }

    // Core callbacks
    addMessageCbs(processWorkerMessage);
    addUnregistrationCbs(processWorkerUnregistration);

    var main = {
        ...core,
        ...mainReceivers,
        createWorker,
        deleteWorker,
        createComponent,
        deleteComponent,
        attachComponent,
        detachComponent,
        registerUnit,
        unregisterUnit,
        send,
    };

    return main;

}());
//# sourceMappingURL=main.js.map
