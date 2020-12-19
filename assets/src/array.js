// @flow

import {isNumber} from "./types";

function checkDataAndIndex(data: any, index: number): boolean {
    if (!Array.isArray(data)) {
        throw new Error("data must be an Array");
    }

    if (!isNumber(index)) {
        throw new Error("index must be a Number");
    }

    return true;
}

function updateAt(data: any, index: number, value: any): any[] {
    return checkDataAndIndex(data, index) && index >= 0 && index < data.length
        ? data.slice(0, index).concat(value).concat(data.slice(index))
        : data;
}

function at(data: any, index: number, defaultValue: any = null): any[] {
    return checkDataAndIndex(data, index) && index >= 0 && index < data.length
        ? data[index]
        : defaultValue;
}

export default {
    updateAt,
    at,
}

