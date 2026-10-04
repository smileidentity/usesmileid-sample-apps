package com.usesmileid.sampleapps.ui.state

/** The ID-number hint and format check from `spec/id-number-hints.json`: the API gives a regex, never an example. */
object UseSmileIDSampleIdNumberHint {

    /** An example that fully matches [regex], or null when the regex uses syntax outside the subset. */
    fun example(regex: String): String? = runCatching { HintParser(regex).parse() }.getOrNull()

    /** What the empty field shows for the chosen type. */
    fun placeholder(type: UseSmileIDSampleKycIdType?): Placeholder = when {
        type == null -> Placeholder.ChooseType
        type.regex.isBlank() || compiled(type.regex) == null -> Placeholder.Enter(type.label)
        else -> example(type.regex)?.let { Placeholder.Example(it) } ?: Placeholder.Enter(type.label)
    }

    /** The trimmed number against the whole regex; a blank regex, or one this engine cannot compile, checks nothing. */
    fun accepts(regex: String, number: String): Boolean {
        val trimmed = number.trim()
        if (trimmed.isEmpty()) return false
        if (regex.isBlank()) return true
        return compiled(regex)?.matches(trimmed) ?: true
    }

    /** The line under a non-empty number that does not fit, which repeats the example; null when it fits. */
    fun error(type: UseSmileIDSampleKycIdType?, number: String): Mismatch? {
        if (type == null || number.isBlank() || accepts(type.regex, number)) return null
        return Mismatch(type.label, example(type.regex))
    }

    /** The empty field's text, worded where it is drawn. */
    sealed interface Placeholder {
        data object ChooseType : Placeholder
        data class Enter(val idType: String) : Placeholder
        data class Example(val example: String) : Placeholder
    }

    /** A number that does not fit [idType]; [example] repeats the hint when there is one. */
    data class Mismatch(val idType: String, val example: String?)

    private fun compiled(regex: String): Regex? = runCatching { Regex(regex) }.getOrNull()
}

private class Unsupported : Exception()

/** A recursive-descent reading of the subset the server's regexes use; anything else throws [Unsupported]. */
private class HintParser(private val source: String) {
    private var at = 0

    fun parse(): String {
        if (peek() == '^') at++
        val out = alternation()
        if (at != source.length) throw Unsupported()
        return out
    }

    private fun peek(): Char? = source.getOrNull(at)

    private fun take(): Char = source.getOrNull(at++) ?: throw Unsupported()

    private fun alternation(): String {
        val first = sequence()
        while (peek() == '|') {
            at++
            sequence()
        }
        return first
    }

    private fun sequence(): String = buildString {
        while (true) {
            val c = peek()
            if (c == null || c == '|' || c == ')') return@buildString
            if (c == '$') {
                at++
                val next = peek()
                if (next != null && next != '|' && next != ')') throw Unsupported()
                continue
            }
            val atom = atom()
            repeat(quantifier()) { append(atom) }
        }
    }

    private fun atom(): String {
        val c = take()
        return when {
            c == '(' -> {
                if (peek() == '?') {
                    at++
                    if (take() != ':') throw Unsupported()
                }
                val inner = alternation()
                if (take() != ')') throw Unsupported()
                inner
            }
            c == '[' -> charClass().toString()
            c == '\\' -> when (val e = take()) {
                'd' -> "0"
                'w' -> "A"
                else -> if (e.isLetterOrDigit()) throw Unsupported() else e.toString()
            }
            c in ".*+?{}^$" -> throw Unsupported()
            else -> c.toString()
        }
    }

    private fun charClass(): Char {
        if (peek() == '^') throw Unsupported()
        val members = mutableListOf<CharRange>()
        while (true) {
            var c = take()
            if (c == ']' && members.isNotEmpty()) break
            if (c == '\\') {
                when (val e = take()) {
                    'd' -> { members += '0'..'9'; continue }
                    'w' -> { members += listOf('A'..'Z', 'a'..'z', '0'..'9', '_'..'_'); continue }
                    else -> if (e.isLetterOrDigit()) throw Unsupported() else c = e
                }
            }
            if (peek() == '-' && source.getOrNull(at + 1).let { it != null && it != ']' }) {
                at++
                val high = take()
                if (high == '\\') throw Unsupported()
                members += c..high
            } else {
                members += c..c
            }
        }
        return listOf('A', '0', 'a').firstOrNull { pick -> members.any { pick in it } } ?: members.first().first
    }

    private fun quantifier(): Int {
        val n = when (peek()) {
            '*', '?' -> { at++; 0 }
            '+' -> { at++; 1 }
            '{' -> {
                val match = BOUNDS.matchAt(source, at) ?: throw Unsupported()
                at = match.range.last + 1
                val low = match.groupValues[1].toInt()
                when {
                    match.groups[2] == null -> low
                    match.groupValues[3].isNotEmpty() -> match.groupValues[3].toInt()
                    else -> maxOf(low, 1)
                }
            }
            else -> return 1
        }
        if (peek() == '?' || peek() == '+' || n > MAX_REPEAT) throw Unsupported()
        return n
    }

    private companion object {
        /** A longer repeat is outside the subset, so an API regex cannot make the hint allocate without limit. */
        const val MAX_REPEAT = 64

        val BOUNDS = Regex("""\{(\d+)(,(\d*))?\}""")
    }
}
