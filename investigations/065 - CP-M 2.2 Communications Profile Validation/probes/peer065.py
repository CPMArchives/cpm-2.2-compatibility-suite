#!/usr/bin/env python3
"""Controlled Unix-socket peer for Investigation 065."""
import argparse
import socket
import time
from pathlib import Path


def connect(path: str, timeout: float) -> socket.socket:
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(path)
            s.settimeout(8)
            return s
        except (FileNotFoundError, ConnectionRefusedError):
            time.sleep(0.05)
    raise TimeoutError(f"socket unavailable: {path}")


def log_line(handle, start, label, data=b""):
    elapsed = time.monotonic() - start
    handle.write(f"{elapsed:.6f}\t{label}\t{data.hex()}\n")
    handle.flush()


def terminal(args):
    start = time.monotonic()
    with open(args.log, "w", encoding="ascii") as out, connect(args.socket, args.timeout) as s:
        log_line(out, start, "CONNECTED")
        marker = b"HOST65-DOWN\r\n"
        s.sendall(marker)
        log_line(out, start, "TX", marker)
        received = bytearray()
        deadline = time.monotonic() + 8
        while b"CPM65-UP\r" not in received and time.monotonic() < deadline:
            chunk = s.recv(256)
            if not chunk:
                break
            received.extend(chunk)
            log_line(out, start, "RX", chunk)
        if args.disconnect:
            log_line(out, start, "FORCED-DISCONNECT")
            return
        echo = b"HOST65-ECHO\r\n"
        s.sendall(echo)
        log_line(out, start, "TX", echo)
        time.sleep(5.0)
        log_line(out, start, "NORMAL-CLOSE")


def read_exact(s, size):
    data = bytearray()
    while len(data) < size:
        chunk = s.recv(size - len(data))
        if not chunk:
            raise EOFError("peer disconnected")
        data.extend(chunk)
    return bytes(data)


def xmodem_receive(args):
    start = time.monotonic()
    payload = bytearray()
    with open(args.log, "w", encoding="ascii") as out, connect(args.socket, args.timeout) as s:
        log_line(out, start, "CONNECTED")
        time.sleep(args.start_delay)
        s.sendall(b"\x15")
        log_line(out, start, "TX-NAK", b"\x15")
        expected = 1
        while True:
            lead = read_exact(s, 1)
            if lead == b"\x04":
                s.sendall(b"\x06")
                log_line(out, start, "RX-EOT-TX-ACK", lead)
                break
            if lead != b"\x01":
                log_line(out, start, "RX-IGNORED", lead)
                continue
            frame = read_exact(s, 131)
            block, inverse = frame[0], frame[1]
            data, checksum = frame[2:130], frame[130]
            valid = inverse == (0xFF - block) and checksum == (sum(data) & 0xFF)
            if args.disconnect_after_block and block == 1:
                log_line(out, start, "FORCED-DISCONNECT-AFTER-BLOCK", lead + frame)
                return
            if args.corrupt_ack and block == 1:
                s.sendall(b"\x15")
                log_line(out, start, "INJECT-NAK", lead + frame)
                args.corrupt_ack = False
                continue
            if not valid or block != expected:
                s.sendall(b"\x15")
                log_line(out, start, "BAD-BLOCK-TX-NAK", lead + frame)
                continue
            payload.extend(data)
            expected = (expected + 1) & 0xFF
            s.sendall(b"\x06")
            log_line(out, start, "RX-BLOCK-TX-ACK", lead + frame)
    Path(args.output).write_bytes(payload)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("mode", choices=("terminal", "xrecv"))
    p.add_argument("--socket", default="/tmp/.z80pack/imsaisim.sio2")
    p.add_argument("--log", required=True)
    p.add_argument("--output")
    p.add_argument("--timeout", type=float, default=15)
    p.add_argument("--start-delay", type=float, default=3.0)
    p.add_argument("--disconnect", action="store_true")
    p.add_argument("--corrupt-ack", action="store_true")
    p.add_argument("--disconnect-after-block", action="store_true")
    args = p.parse_args()
    if args.mode == "terminal":
        terminal(args)
    else:
        if not args.output:
            p.error("xrecv requires --output")
        xmodem_receive(args)


if __name__ == "__main__":
    main()
