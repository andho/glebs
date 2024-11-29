import { toBitArray } from "../gleam_stdlib/gleam.mjs"
import { Ok, Error } from "./gleam.mjs";

export function getRandomValues(data) {
  try {
    crypto.getRandomValues(data.buffer);
    return new Ok(toBitArray(data.buffer));
  } catch (e) {
    return new Error(e.message);
  }
}

export async function hash(string_to_hash) {
  const utf8 = new TextEncoder().encode(string_to_hash);
  const hashBuffer = await crypto.subtle.digest('SHA-256', utf8);
  let a = new Uint8Array(hashBuffer);
  return new Ok(toBitArray(a))
}
