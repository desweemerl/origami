// @flow

/**
 * Unit can be worker or component.
 */
let id = 0; // ID counter
const aliases: { [alias: string]: number } = {};
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

export const addMessageCbs = pushCallback(messageCbs);
export const addRegistrationCbs = pushCallback(registrationCbs);
export const addUnregistrationCbs = pushCallback(unregistrationCbs);

function checkId(id: number): boolean {
    if (!(id in units)) {
        throw new Error(`unit with id ${id} doesn't exist`);
    }

    return id;
}

function getIdFromAlias(alias: string): number {
    if (!(alias in aliases)) {
        throw new Error(`alias ${idOrAlias} is not registered`);
    }

    return aliases[alias];
}

function getUnitId(idOrAlias: number | string): number {
    return typeof idOrAlias === "string"
        ? getIdFromAlias(idOrAlias)
        : idOrAlias;
}

function checkAndGetUnit(id): any {
    return units[checkId(id)];
}

export function getUnit(idOrAlias: number | string): any {
    const id = getUnitId(idOrAlias);

    return checkAndGetUnit(id);
}

export function send(idOrAlias: number | string, message: any): true {
    const id = getUnitId(idOrAlias);
    const unit = checkAndGetUnit(id);

    return seekMessageCbs({unit, message, id});
}

export function registerUnit(unit, alias) {
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

export function unregisterUnit(idOrAlias) {
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

