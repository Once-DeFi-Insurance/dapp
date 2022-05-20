import React from "react";

/**
 * web3 props can be passed from '../App.jsx' into your local view component for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded using ethers contract module. More here https://docs.ethers.io/v5/api/contract/contract/
 * @returns react component
 **/
function Home({ readContracts }) {
  // you can also use hooks locally in your component of choice
  // in this case, let's keep track of 'purpose' variable from our contract

  return (
    <div>
      <h2>Once Defi Insurance</h2>
      <div style={{ margin: 32 }}>
        <span style={{ marginRight: 8 }}></span>A decentralized risk management system That disintermediates the Life
        assurance industry and globalizes the tokenized value of peoples lives on the NFT marketplace
      </div>
    </div>
  );
}

export default Home;
