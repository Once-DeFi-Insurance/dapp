const { WrapperBuilder } = require("redstone-evm-connector");

describe("Example Custom URL (on-demand)", function () {
  let exampleContract;

  beforeEach(async () => {
    const ExampleContract = await ethers.getContractFactory("ExampleContractCustomUrlsOnDemand");
    exampleContract = await ExampleContract.deploy();
  });

  it("Custom URL test", async function () {
    exampleContract = WrapperBuilder
      .wrapLite(exampleContract)
      .usingCustomRequestsOnDemand({
        nodes: [
          "https://requests-proxy-node-1.redstone.finance",
        ],
        customRequestDetails: {
          url: "https://oncedata.free.beeceptor.com/bruno",
          jsonpath: "$.Status",
          expectedSymbol: "0x44a8ba120d400973",
        },
      });
    const valueFromOracle = await exampleContract.getValue();
    console.log({ valueFromOracle: valueFromOracle.toNumber() });
  });
});
