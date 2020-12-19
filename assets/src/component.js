// @flow

import {addMessageCbs, addUnregistrationCbs, getUnit, registerUnit, send, unregisterUnit} from "./unit";
import {receiversFactory} from "./receiver";
import {storeFactory} from "./store";
import {isObject} from "./types";

const componentFlag = {};
const componentStores = {};
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

export function createComponent({logic, render, alias, parentNode}) {
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
    componentStores[id] = store;

    logic({
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

export function deleteComponent(idOrdAlias) {
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

export function attachComponent(idOrAlias, parentNode) {
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

export function detachComponent(idOrAlias) {
    return detachComponentNodes(getUnit(idOrAlias));
}

addMessageCbs(processComponentMessage);
addUnregistrationCbs(processComponentUnregistration);
