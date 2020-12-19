var M = (function () {
    'use strict';

    // 
    const isObject = (value) => typeof value === "object" && value !== null && value.constructor === Object;
    const isNumber = (value) => typeof value === "number" && !isNaN(value) && isFinite(value);
    const isString = (value) => typeof value === "string";
    const isFunction = (value) => typeof value === "function";
    const isArray = (value) => Array.isArray(value);
    const isUndefined = (value) => typeof value === "undefined";

    var types = {
        isObject,
        isNumber,
        isString,
        isFunction,
        isArray,
        isUndefined,
    };

    // 

    const throwError = (error) => {
        const e = isString(error) ? new Error(error) : error;
        throw e;
    };

    // 

    const pipe = (...fns) => (value) => fns.reduce((acc, fn) => fn(acc), value);
    const tap = (...fns) => (value) => fns.reduce((acc, fn) => {
        fn(acc);
        return acc
    }, value);

    // 

    const logFactory =
        (logger = console.log) => (...data) => {
            logger(...data);
            return data;
        };

    var logger = {
        logFactory,
        log: logFactory(),
        error: logFactory(console.error),
        debug: logFactory(console.debug),
    };

    // 



    const receivers = [];

    const registerReceiver =
            pipe(
                (receiver) => logger.log("Registering receiver", receiver) && receiver,
                (receiver) =>
                    receivers.includes(receiver)
                        ? {exists: true, receiver}
                        : receivers.push(receiver) && {exists: false, receiver}
            );

    const receive = (message) => receivers.some((receiver) => receiver(message));

    // 



    const ids = {
        worker: null,
        cid: 0,
    };

    const getOrigin = () =>
        ({id: ids.worker});

    // 

    const checkDataAndIndex = (data, index) =>
        !isArray(data)
            ? throwError("data must be an Array")
            : !isNumber(index)
                ? throwError("index must be a Number")
                : true;

    const updateAt = (data, index, value) =>
        checkDataAndIndex(data, index) && index >= 0 && index < data.length
            ? data.slice(0, index).concat(value).concat(data.slice(index))
            : data;

    const at = (data, index, defaultValue = null) =>
        checkDataAndIndex(data, index) && index >= 0 && index < data.length
            ? data[index]
            : defaultValue;

    var array = {
        updateAt,
        at,
    };

    // 

    const checkData = (data) =>
        isObject(data)
            ? true
            : throwError("data must be an Object");

    const get = (data, key, defaultValue = null) =>
        checkData(data) && data.hasOwnProperty(key) ? data[key] : defaultValue;

    const put = (data, key, value) =>
        checkData(data) && {...data, [key]: value};

    var dict = {
        get,
        put,
    };

    // 


    var core = {
        ...types,
        ...array,
        ...dict,
        logger,
        pipe,
    };

    // 


    const workerIDs = {
        lastID: 0,
        workers: {}
    };

    const createWorker = (jsFile) => new Promise(
        (resolve, reject) => {
            const id = ++workerIDs.lastID;
            const worker = new Worker(jsFile);

            worker.onerror = (err) => {
                logger.error(`Failed to create worker with js ${jsFile}`, err);
                deleteWorker(id);
                reject(err);
            };

            workerIDs.workers[id] = worker;
            worker.postMessage({
                data: {
                    action: "init",
                    id: id,
                },
                origin: getOrigin(),
            });

            let firstMessage = true;
            worker.onmessage =
                tap(
                    (event) => logger.log(`Receiving data from worker with id ${id}`, event),
                    (event) => {
                        receive({data: event.data, origin: {id, worker}});
                        if (firstMessage) {
                            firstMessage = false;
                            resolve({id, worker});
                        }
                    }
                );
    /*
            Object.entries(workerIDs.workers)
                .filter(([wid, _]) => wid !== id.toString())
                .forEach(([_, worker]) => worker.postMessage({
                    data: {
                        action: "addWorker",
                        id: "id",
                    }
                }));
    */
        }
    );

    const deleteWorker = (id) =>
        id in workerIDs
            ? !!delete (workerIDs[id])
            : false;

    const workerReceiver = ({data, origin}) =>
        !isObject(data) || !isString(data.action)
                ? true
                    : data.action === "createWorker"
                        ? isString(data.jsFile)
                            ? createWorker(data.jsFile) && false
                            : throwError("bad jsFile from action")
                        : data.action === "stopWorker"
                            ? isObject(data.origin)
                                ? deleteWorker(data.origin)
                                : throwError("origin is missing from action")
                            : data.action === "workerInitialized"
                                ? true : true;

    let initialized = false;
    const init = () => {
        initialized && throwError("init called twice");
        registerReceiver(workerReceiver);
        initialized = true;
    };

    var render = {
        ...core,
        init,
        createWorker,
    };

    return render;

}());
