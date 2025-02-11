// chaos-lambda-extension/extension/src/main.rs
use anyhow::{Context, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;
use std::io::Write;
use tokio::time;

#[derive(Debug, Serialize)]
struct RegisterRequest {
    events: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct RegisterResponse {
    extension_id: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    // Process environment variables
    let block_hosts = env::var("CHAOS_BLOCK_HOSTS").unwrap_or_default();
    log::info!("Received block list: {}", block_hosts);

    // Write blocked hosts to shared file
    let entries: Vec<&str> = block_hosts.split(',').collect();
    let mut file = File::create("/tmp/chaos_blocked_hosts.txt")
        .context("Failed to create blocked hosts file")?;
    
    for entry in entries {
        let sanitized = entry.trim();
        if !sanitized.is_empty() {
            writeln!(file, "{}", sanitized)
                .context("Failed to write to blocked hosts file")?;
        }
    }

    // Register extension
    let runtime_api = env::var("AWS_LAMBDA_RUNTIME_API")
        .context("Missing AWS_LAMBDA_RUNTIME_API environment variable")?;
    
    let client = Client::new();
    let register_url = format!("http://{}/2020-01-01/extension/register", runtime_api);

    let response = client.post(&register_url)
        .header("Lambda-Extension-Name", "chaos-network-extension")
        .json(&RegisterRequest {
            events: vec!["INVOKE".to_string(), "SHUTDOWN".to_string()],
        })
        .send()
        .await
        .context("Extension registration failed")?;

    let register_response: RegisterResponse = response.json()
        .await
        .context("Failed to parse registration response")?;

    let extension_id = register_response.extension_id;
    log::info!("Registered extension with ID: {}", extension_id);

    // Main event loop
    let event_url = format!("http://{}/2020-01-01/extension/event/next", runtime_api);
    
    loop {
        let event_response = client.get(&event_url)
            .header("Lambda-Extension-Identifier", &extension_id)
            .send()
            .await
            .context("Failed to get next event")?;

        if !event_response.status().is_success() {
            log::error!("Received error status: {}", event_response.status());
            time::sleep(time::Duration::from_secs(1)).await;
            continue;
        }

        let event = event_response.json::<serde_json::Value>()
            .await
            .context("Failed to parse event payload")?;

        match event["eventType"].as_str() {
            Some("SHUTDOWN") => {
                log::info!("Received shutdown event");
                break;
            }
            Some("INVOKE") => log::debug!("Received invoke event"),
            _ => log::warn!("Received unknown event type"),
        }
    }

    log::info!("Extension shutting down");
    Ok(())
}