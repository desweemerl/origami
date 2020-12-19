describe("Tests on component", () => {
    describe("function.ex set", () => {
        it("must create element with no delay", () => {
            function js({store}) {
                store.set("node1 content", "message1");
            }

            function render({store, nodes, parentNode, init}) {
                if (init) {
                    const n1 = document.createElement("div");
                    n1.setAttribute("id", "node1");
                    n1.textContent = store.get("message1");
                    nodes.push(n1);
                }
            }

            W.createComponent({js, render, parentNode: document.body});

            const node = document.getElementById("node1");
            chai.expect(node.textContent).to.be.equal("node1 content");
        });

        it("must create element with delay of 10ms", (done) => {
            function js({store}) {
                window.setTimeout(() => {
                    store.set("node2 content", "message2");
                }, 10);
            }

            function render({store, nodes, parentNode, init}) {
                if (init) {
                    const n1 = document.createElement("div");
                    n1.setAttribute("id", "node2");
                    n1.textContent = store.get("message2");
                    nodes.push(n1);
                } else {
                    nodes[0].textContent = store.get("message2");
                }
            }

            W.createComponent({js, render, parentNode: document.body});
            window.setTimeout(() => {
                const node = document.getElementById("node2");
                chai.expect(node.textContent).to.be.equal("node2 content");
                done();
            }, 20);
        })
    });
});
