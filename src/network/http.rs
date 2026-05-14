
use log::{debug, warn};
use std::time::Duration;
/// Result of a completed HTTP request, including both success and error cases.
pub struct HttpResponse {
    /// HTTP status code; `0` when the request failed before receiving a response.
    pub status: u16,
    /// Raw response body bytes; empty on network error.
    pub body: Vec<u8>,
    /// Response header name-value pairs.
    pub headers: Vec<(String, String)>,
    /// Human-readable error message when the request failed; `None` on success.
    pub error: Option<String>,
}
/// Execute a synchronous HTTP request; returns an `HttpResponse` with `error` set on failure.
pub fn execute_request(
    method: &str,
    url: &str,
    headers: &[(String, String)],
    body: Option<&[u8]>,
    timeout_secs: u64,
) -> HttpResponse {
    debug!("HTTP {} {}", method, url);
    let agent = if timeout_secs > 0 {
        ureq::Agent::config_builder()
            .timeout_global(Some(Duration::from_secs(timeout_secs)))
            .build()
            .new_agent()
    } else {
        ureq::Agent::new_with_defaults()
    };
    let result = execute_with_agent(&agent, method, url, headers, body);
    match result {
        Ok(resp) => resp,
        Err(e) => {
            warn!("HTTP request failed: {} {} — {}", method, url, e);
            HttpResponse {
                status: 0,
                body: Vec::new(),
                headers: Vec::new(),
                error: Some(e),
            }
        }
    }
}
/// Dispatch the request using a pre-configured `Agent`; return a parsed `HttpResponse` or error message.
#[allow(clippy::wildcard_in_or_patterns)]
fn execute_with_agent(
    agent: &ureq::Agent,
    method: &str,
    url: &str,
    headers: &[(String, String)],
    body: Option<&[u8]>,
) -> Result<HttpResponse, String> {
    let method_upper = method.to_uppercase();
    let response = match method_upper.as_str() {
        "POST" | "PUT" | "PATCH" => {
            let mut request = match method_upper.as_str() {
                "POST" => agent.post(url),
                "PUT" => agent.put(url),
                "PATCH" => agent.patch(url),
                _ => unreachable!(),
            };
            for (name, value) in headers {
                request = request.header(name, value);
            }
            if let Some(body_data) = body {
                request
                    .send(body_data)
                    .map_err(|e| format!("request error: {e}"))?
            } else {
                request
                    .send(&[] as &[u8])
                    .map_err(|e| format!("request error: {e}"))?
            }
        }
        "GET" | "HEAD" | "OPTIONS" | "DELETE" | _ => {
            let mut request = match method_upper.as_str() {
                "HEAD" => agent.head(url),
                "DELETE" => agent.delete(url),
                _ => agent.get(url),
            };
            for (name, value) in headers {
                request = request.header(name, value);
            }
            request.call().map_err(|e| format!("request error: {e}"))?
        }
    };
    let status = response.status();
    let mut resp_headers: Vec<(String, String)> = Vec::new();
    for name in response.headers().keys() {
        if let Some(value) = response.headers().get(name) {
            let value_str = value.to_str().unwrap_or("");
            resp_headers.push((name.to_string(), value_str.to_string()));
        }
    }
    let body_bytes = response
        .into_body()
        .read_to_vec()
        .map_err(|e| format!("failed to read response body: {e}"))?;
    Ok(HttpResponse {
        status: status.into(),
        body: body_bytes,
        headers: resp_headers,
        error: None,
    })
}
