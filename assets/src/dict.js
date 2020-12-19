// @flow

import {isObject} from "./types";

function checkDataAndKey(data: any, key: any): boolean {
    if (!isObject(data)) {
        throw new Error("data must be an Object");
    }

    if (typeof key !== "string") {
        throw new Error("key must be a string");
    }

    return true;
}

function get(data: any, key: string, defaultValue: any = null): any {
    return checkDataAndKey(data, key) && (key in data) ? data[key] : defaultValue;
}

function put(data: any, key: string, value: any): any {
    return checkDataAndKey(data, key) && {...data, [key]: value};
}

export default {
    get,
    put,
}
