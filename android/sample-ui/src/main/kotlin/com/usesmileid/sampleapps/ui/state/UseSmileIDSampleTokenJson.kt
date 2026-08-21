package com.usesmileid.sampleapps.ui.state

/**
 * The smallest JSON reader that can tell a string from a number from a boolean, which is what every
 * token binding rule turns on. Hand-written rather than pulled in: `sample-ui` carries no JSON
 * dependency, and [UseSmileIDSampleTokenDecoder] has to run as a plain JVM test.
 */
internal sealed interface TokenJson {
    data class Obj(val members: Map<String, TokenJson>) : TokenJson

    data class Arr(val items: List<TokenJson>) : TokenJson

    data class Str(val value: String) : TokenJson

    /** Held as written, so an epoch second reads back exactly. */
    data class Num(val literal: String) : TokenJson

    data class Bool(val value: Boolean) : TokenJson

    data object Null : TokenJson
}

internal fun TokenJson.Obj.obj(key: String): TokenJson.Obj? = members[key] as? TokenJson.Obj

internal fun TokenJson.Obj.string(key: String): String? = (members[key] as? TokenJson.Str)?.value

internal fun TokenJson.Obj.boolean(key: String): Boolean? = (members[key] as? TokenJson.Bool)?.value

/** RFC 7519 allows a non-integer NumericDate, so the literal reads as a Double and truncates. */
internal fun TokenJson.Obj.seconds(key: String): Long? =
    (members[key] as? TokenJson.Num)?.literal?.toDoubleOrNull()?.takeIf { it.isFinite() }?.toLong()

/**
 * Null on anything malformed or trailing; the caller turns that into a rejection with a reason.
 * A token arrives from a clipboard or a QR code, so its nesting is untrusted: without a cap a deeply
 * nested payload takes the app down with a StackOverflowError.
 */
internal fun parseTokenJson(text: String): TokenJson? = TokenJsonReader(text).parse()

private class TokenJsonReader(private val text: String) {
    private var at = 0

    fun parse(): TokenJson? {
        val value = value(depth = 0) ?: return null
        skipWhitespace()
        return value.takeIf { at == text.length }
    }

    private fun value(depth: Int): TokenJson? {
        // Untrusted nesting: capped, see parseTokenJson.
        if (depth > MAX_DEPTH) return null
        skipWhitespace()
        return when (text.getOrNull(at) ?: return null) {
            '{' -> obj(depth)
            '[' -> arr(depth)
            '"' -> string()?.let(TokenJson::Str)
            't' -> literal("true", TokenJson.Bool(true))
            'f' -> literal("false", TokenJson.Bool(false))
            'n' -> literal("null", TokenJson.Null)
            else -> number()
        }
    }

    private fun obj(depth: Int): TokenJson.Obj? {
        at++
        val members = mutableMapOf<String, TokenJson>()
        skipWhitespace()
        if (text.getOrNull(at) == '}') {
            at++
            return TokenJson.Obj(members)
        }
        while (true) {
            skipWhitespace()
            if (text.getOrNull(at) != '"') return null
            val key = string() ?: return null
            skipWhitespace()
            if (text.getOrNull(at) != ':') return null
            at++
            members[key] = value(depth + 1) ?: return null
            skipWhitespace()
            when (text.getOrNull(at)) {
                ',' -> at++
                '}' -> {
                    at++
                    return TokenJson.Obj(members)
                }
                else -> return null
            }
        }
    }

    private fun arr(depth: Int): TokenJson.Arr? {
        at++
        val items = mutableListOf<TokenJson>()
        skipWhitespace()
        if (text.getOrNull(at) == ']') {
            at++
            return TokenJson.Arr(items)
        }
        while (true) {
            items += value(depth + 1) ?: return null
            skipWhitespace()
            when (text.getOrNull(at)) {
                ',' -> at++
                ']' -> {
                    at++
                    return TokenJson.Arr(items)
                }
                else -> return null
            }
        }
    }

    private fun string(): String? {
        at++
        val value = StringBuilder()
        while (true) {
            val char = text.getOrNull(at) ?: return null
            at++
            when {
                char == '"' -> return value.toString()
                char != '\\' -> value.append(char)
                else -> value.append(escape() ?: return null)
            }
        }
    }

    private fun escape(): Char? {
        val marker = text.getOrNull(at) ?: return null
        at++
        return when (marker) {
            '"', '\\', '/' -> marker
            'b' -> '\b'
            'f' -> '\u000C'
            'n' -> '\n'
            'r' -> '\r'
            't' -> '\t'
            'u' -> unicodeEscape()
            else -> null
        }
    }

    private fun unicodeEscape(): Char? {
        if (at + HEX_DIGITS > text.length) return null
        val code = text.substring(at, at + HEX_DIGITS).toIntOrNull(radix = HEX_RADIX) ?: return null
        at += HEX_DIGITS
        return code.toChar()
    }

    private fun literal(word: String, value: TokenJson): TokenJson? {
        if (!text.startsWith(word, at)) return null
        at += word.length
        return value
    }

    private fun number(): TokenJson.Num? {
        val start = at
        if (text.getOrNull(at) == '-') at++
        while (text.getOrNull(at)?.isNumberPart() == true) at++
        val literal = text.substring(start, at)
        // Checked here rather than at the call site, so `{"exp":+}` cannot read as a claim.
        return TokenJson.Num(literal).takeIf { literal.toDoubleOrNull()?.isFinite() == true }
    }

    private fun Char.isNumberPart(): Boolean = isDigit() || this in NUMBER_PUNCTUATION

    private fun skipWhitespace() {
        while (text.getOrNull(at)?.isWhitespace() == true) at++
    }

    private companion object {
        const val MAX_DEPTH = 32
        const val HEX_DIGITS = 4
        const val HEX_RADIX = 16
        const val NUMBER_PUNCTUATION = ".eE+-"
    }
}
