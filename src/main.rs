use std::env;
use std::error::Error;
use std::io::Read;

use url::{ParseError, Url};

use crate::nur::Nur;

mod nur;

#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;


fn cli_url(short: String) -> Result<Url, ParseError> {
    if short.starts_with("@") {
        return Url::parse("https://nur.tools")?.join(&short[1..]);
    }
    if short.starts_with("http://") || short.starts_with("https://") {
        return Url::parse(&short);
    }
    Url::parse(format!("https://{short}").as_str())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let url = env::args().nth(1).and_then(|s| cli_url(s).ok())
        .unwrap_or(Url::parse("https://nur.tools/badurl").unwrap());
    Nur::new(url)?.run().await
}
