describe("Tests on help functions", () => {
    describe("match fn", () => {
        it("must match", () => {
            chai.expect(W.match(5, 5)).to.be.true;
        });

        it("must match", () => {
            chai.expect(W.match({value: 5, key: "ok"}, {value: 5})).to.be.true;
        });

        it("must match", () => {
            chai.expect(W.match({data: {ok :5}, other: 123}, {data: {ok: 5}})).to.be.true;
        });

    });
});
