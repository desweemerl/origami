// @flow

import core from "./core";
import {isNumber} from "./types";
import {matchFn} from "./function";
import {receiversFactory} from "./receiver";

let id, alias;

const workerReceivers = receiversFactory();

function send(message): void {
    postMessage(message);
}

onmessage = function _onMessage(event) {
    workerReceivers.sendToReceivers(event.data);
}

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

export default {
    ...core,
    ...workerReceivers,
    send,
}
