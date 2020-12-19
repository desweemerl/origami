// @flow

import array from "./array";
import dict from "./dict";
import {isNumber, isObject} from "./types";


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

export function storeFactory(data, onTouchedPathChange) {
    if (typeof data === "undefined") {
        data = {}
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
