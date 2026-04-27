//! HTTP client for async web requests on the network thread.
//!
//! Executes HTTP requests using the `ureq` crate. All requests run on the
//! dedicated network thread (see [`super::net_thread`]); the Lua API layer
//! only sees the request/response IDs and completion callbacks.
//!
//! # Supported methods
//!
//! GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS.
//!
//! # TLS
//!
//! Uses `rustls` (via ureq default features) for HTTPS — no OpenSSL dependency.

use std::time::Duration;

use log::{debug, warn};

/// Result of an HTTP request execution.
///
/// # Fields
/// - `status` — HTTP status code (0 if connection failed before receiving a response).
/// - `body` — Response body bytes.
/// - `headers` — Response headers as key-value pairs.
/// - `error` — Error message if the request failed (`None` on success).
pub struct HttpResponse {
    /// HTTP status code (0 if the request never reached a server).
    pub status: u16,
    /// Response body as raw bytes.
    pub body: Vec<u8>,
    /// Response headers as `(name, value)` pairs.
    pub headers: Vec<(String, String)>,
    /// Error message if the request failed; `None` on success.
    pub error: Option<String>,
}

/// Execute an HTTP request synchronously (called from the network thread).
///
/// # Parameters
/// - `method` — HTTP method string (e.g. `"GET"`, `"POST"`).
/// - `url` — Target URL including scheme (e.g. `"https://api.example.com/data"`).
/// - `headers` — Request headers as `(name, value)` pairs.
/// - `body` — Optional request body bytes.
/// - `timeout_secs` — Request timeout in seconds (0 for no timeout).
///
/// # Returns
/// [`HttpResponse`] — always returns a response (errors encoded in the `error` field).
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

/// Internal: execute the request using a configured agent.
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

    // Collect response headers
    let mut resp_headers: Vec<(String, String)> = Vec::new();
    for name in response.headers().keys() {
        if let Some(value) = response.headers().get(name) {
            let value_str = value.to_str().unwrap_or("");
            resp_headers.push((name.to_string(), value_str.to_string()));
        }
    }

    // Read response body
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn http_response_default_fields() {
        let resp = HttpResponse {
            status: 200,
            body: vec![72, 105],
            headers: vec![("Content-Type".to_string(), "text/plain".to_string())],
            error: None,
        };
        assert_eq!(resp.status, 200);
        assert_eq!(resp.body, b"Hi");
        assert!(resp.error.is_none());
    }

    #[test]
    fn http_response_with_error() {
        let resp = HttpResponse {
            status: 0,
            body: Vec::new(),
            headers: Vec::new(),
            error: Some("connection refused".to_string()),
        };
        assert_eq!(resp.status, 0);
        assert!(resp.error.unwrap().contains("connection refused"));
    }

    #[test]
    fn http_response_empty_body_and_headers() {
        let resp = HttpResponse {
            status: 204,
            body: Vec::new(),
            headers: Vec::new(),
            error: None,
        };
        assert_eq!(resp.status, 204);
        assert!(resp.body.is_empty());
        assert!(resp.headers.is_empty());
    }

    #[test]
    fn http_response_multiple_headers() {
        let resp = HttpResponse {
            status: 200,
            body: Vec::new(),
            headers: vec![
                ("X-A".to_string(), "1".to_string()),
                ("X-B".to_string(), "2".to_string()),
            ],
            error: None,
        };
        assert_eq!(resp.headers.len(), 2);
        assert_eq!(resp.headers[0].0, "X-A");
    }
}
