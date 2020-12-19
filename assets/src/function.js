// @flow

import {isNumber, isObject} from "./types";

export function pipe(): (value: any) => any {
    const fns = arguments;

    return function _pipe(value: any): any {
        let result = value;

        for (let i = 0; i < fns.length; i++) {
            result = fns[i](result);
        }

        return result;
    }
}

function matchObjects(a: any, b: any): boolean {
    for (let k in b) {
        if (!(k in a) || !match(a[k], b[k])) {
            return false;
        }
    }

    return true;
}

function matchArrays(a: any[], b: any[]): boolean {
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

export function match(a: any, b: any): boolean {
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

export function matchFn(b: any, callback: (any) => void) {
    return function _matchFn(a) {
        if (match(a, b)) {
            callback(a);
            return true;
        }

        return false;
    }
}

export default {
    pipe,
    match,
    matchFn,
}
