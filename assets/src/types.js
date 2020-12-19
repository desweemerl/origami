// @flow

export function isObject(value: any): boolean {
    return typeof value === "object" && value !== null && value.constructor === Object;
}

export function isNumber(value: any): boolean {
    return typeof value === "number" && !Number.isNaN(value) && Number.isFinite(value);
}

export default {
    isObject,
    isNumber,
};
