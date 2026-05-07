//! INTERNAL ONLY: Rust-only tests for data internals that are not exposed as `lurek.data.*`.

// ── ring_buffer ───────────────────────────────────────────────────────────────

mod ring_buffer_tests {
    use lurek2d::data::RingBuffer;

    #[test]
    fn zero_capacity_clamped_to_one() {
        let rb = RingBuffer::<i32>::new(0);
        assert_eq!(rb.capacity(), 1);
    }

    #[test]
    fn push_returns_true_when_space_available() {
        let mut rb = RingBuffer::new(2);
        assert!(rb.push(1));
        assert!(rb.push(2));
        assert!(!rb.push(3)); // full, overwrites
    }
}

// ── compress ──────────────────────────────────────────────────────────────────

mod compress_tests {
    use std::io::Cursor;

    use lurek2d::data::{
        compress_chunks, compress_stream, decompress_chunks, decompress_stream, CompressFormat,
    };

    fn sample_payload() -> Vec<u8> {
        let mut data = Vec::new();
        for i in 0..4096_u32 {
            data.extend_from_slice(format!("row:{:04};", i).as_bytes());
        }
        data
    }

    #[test]
    fn stream_round_trip_for_all_formats() {
        let payload = sample_payload();
        let formats = [
            CompressFormat::Deflate,
            CompressFormat::Gzip,
            CompressFormat::Lz4,
            CompressFormat::Zlib,
        ];

        for format in formats {
            let mut compressed = Vec::new();
            compress_stream(Cursor::new(&payload), &mut compressed, format, 6)
                .expect("compress_stream should succeed");

            let mut restored = Vec::new();
            decompress_stream(Cursor::new(&compressed), &mut restored, format)
                .expect("decompress_stream should succeed");

            assert_eq!(restored, payload, "format {:?}", format);
        }
    }

    #[test]
    fn chunk_helpers_round_trip_for_all_formats() {
        let payload = sample_payload();
        let chunks: Vec<&[u8]> = payload.chunks(97).collect();
        let formats = [
            CompressFormat::Deflate,
            CompressFormat::Gzip,
            CompressFormat::Lz4,
            CompressFormat::Zlib,
        ];

        for format in formats {
            let compressed =
                compress_chunks(&chunks, format, 7).expect("compress_chunks should succeed");
            let compressed_chunks: Vec<&[u8]> = compressed.chunks(53).collect();
            let restored = decompress_chunks(&compressed_chunks, format)
                .expect("decompress_chunks should succeed");

            assert_eq!(restored, payload, "format {:?}", format);
        }
    }

    #[test]
    fn stream_level_is_clamped_for_flate_formats() {
        let payload = sample_payload();

        for format in [
            CompressFormat::Deflate,
            CompressFormat::Gzip,
            CompressFormat::Zlib,
        ] {
            let mut compressed = Vec::new();
            compress_stream(Cursor::new(&payload), &mut compressed, format, 99)
                .expect("compress_stream should clamp level and succeed");

            let mut restored = Vec::new();
            decompress_stream(Cursor::new(&compressed), &mut restored, format)
                .expect("decompress_stream should succeed");

            assert_eq!(restored, payload, "format {:?}", format);
        }
    }
}
