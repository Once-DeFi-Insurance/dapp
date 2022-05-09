import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header({ link, title, subTitle }) {
  return (
    <a href={link} target="_blank" rel="noopener noreferrer">
      <PageHeader title={title} subTitle={subTitle} style={{ cursor: "pointer" }} />
    </a>
  );
}

Header.defaultProps = {
  link: "https://github.com/Once-DeFi-Insurance",
  title: "🫶 Once Defi Insurance",
  subTitle: "savings for your financial future",
};
