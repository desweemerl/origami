// @flow

import {addMessageCbs, addUnregistrationCbs, registerUnit, send, unregisterUnit} from "./unit";
import logger from "./logger";
import core from "./core";
import {receiversFactory} from "./receiver";
import {attachComponent, createComponent, deleteComponent, detachComponent} from "./component";

const mainReceivers = receiversFactory();

function createWorker(jsFile: string, alias: string) {
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
            }
        }
    );
}

function deleteWorker(idOrAlias: number): boolean {
    return unregisterUnit(idOrAlias);
}

function processWorkerMessage({unit, message}): boolean {
    if (unit instanceof Worker) {
        unit.postMessage(message);

        return true;
    }

    return false;
}

function processWorkerUnregistration({unit}): boolean {
    if (unit instanceof Worker) {
        unit.terminate();

        return true;
    }

    return false;
}

// Core callbacks
addMessageCbs(processWorkerMessage);
addUnregistrationCbs(processWorkerUnregistration);

export default {
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
}
