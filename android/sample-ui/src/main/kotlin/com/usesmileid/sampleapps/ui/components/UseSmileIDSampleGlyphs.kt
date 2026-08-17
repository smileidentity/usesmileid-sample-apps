package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import com.smileid.designsystem.SmileDimens

/** Drawn rather than imported, because `material-icons` is not on this classpath. Public because the slot APIs take one. */
@Composable
fun BackArrowGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    val inset = s.width
    val midY = this.size.height / 2f
    drawLine(tint, Offset(this.size.width - inset, midY), Offset(inset, midY), s.width, StrokeCap.Round)
    drawPath(
        path = Path().apply {
            moveTo(inset + this@Canvas.size.width * 0.3f, midY - this@Canvas.size.height * 0.28f)
            lineTo(inset, midY)
            lineTo(inset + this@Canvas.size.width * 0.3f, midY + this@Canvas.size.height * 0.28f)
        },
        color = tint,
        style = s,
    )
}

@Composable
fun ChevronRightGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    drawPath(
        path = Path().apply {
            moveTo(this@Canvas.size.width * 0.36f, this@Canvas.size.height * 0.22f)
            lineTo(this@Canvas.size.width * 0.66f, this@Canvas.size.height * 0.5f)
            lineTo(this@Canvas.size.width * 0.36f, this@Canvas.size.height * 0.78f)
        },
        color = tint,
        style = s,
    )
}

@Composable
fun CheckGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    drawPath(
        path = Path().apply {
            moveTo(this@Canvas.size.width * 0.2f, this@Canvas.size.height * 0.53f)
            lineTo(this@Canvas.size.width * 0.42f, this@Canvas.size.height * 0.74f)
            lineTo(this@Canvas.size.width * 0.8f, this@Canvas.size.height * 0.28f)
        },
        color = tint,
        style = s,
    )
}

@Composable
fun TrashGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    val w = this.size.width
    val h = this.size.height
    drawLine(tint, Offset(w * 0.16f, h * 0.28f), Offset(w * 0.84f, h * 0.28f), s.width, StrokeCap.Round)
    drawLine(tint, Offset(w * 0.38f, h * 0.28f), Offset(w * 0.38f, h * 0.16f), s.width, StrokeCap.Round)
    drawLine(tint, Offset(w * 0.62f, h * 0.28f), Offset(w * 0.62f, h * 0.16f), s.width, StrokeCap.Round)
    drawPath(
        path = Path().apply {
            moveTo(w * 0.24f, h * 0.28f)
            lineTo(w * 0.3f, h * 0.86f)
            lineTo(w * 0.7f, h * 0.86f)
            lineTo(w * 0.76f, h * 0.28f)
        },
        color = tint,
        style = s,
    )
}

/** The Scan token app bar's trailing control — a bolt, because the design labels it torch/flash. */
@Composable
fun TorchGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val w = this.size.width
    val h = this.size.height
    drawPath(
        path = Path().apply {
            moveTo(w * 0.56f, h * 0.08f)
            lineTo(w * 0.24f, h * 0.55f)
            lineTo(w * 0.46f, h * 0.55f)
            lineTo(w * 0.42f, h * 0.92f)
            lineTo(w * 0.76f, h * 0.44f)
            lineTo(w * 0.54f, h * 0.44f)
            close()
        },
        color = tint,
        style = stroke(),
    )
}

@Composable
fun CopyGlyph(tint: Color, size: Dp = SmileDimens.sizeIconSm) = Canvas(Modifier.size(size)) {
    val s = stroke()
    val w = this.size.width
    val h = this.size.height
    val corner = w * 0.12f
    drawRoundRect(
        color = tint,
        topLeft = Offset(w * 0.3f, h * 0.3f),
        size = Size(w * 0.56f, h * 0.56f),
        cornerRadius = CornerRadius(corner, corner),
        style = s,
    )
    drawPath(
        path = Path().apply {
            moveTo(w * 0.7f, h * 0.16f)
            lineTo(w * 0.16f, h * 0.16f)
            lineTo(w * 0.16f, h * 0.7f)
        },
        color = tint,
        style = s,
    )
}

@Composable
fun PlusGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    val w = this.size.width
    val h = this.size.height
    drawLine(tint, Offset(w * 0.5f, h * 0.2f), Offset(w * 0.5f, h * 0.8f), s.width, StrokeCap.Round)
    drawLine(tint, Offset(w * 0.2f, h * 0.5f), Offset(w * 0.8f, h * 0.5f), s.width, StrokeCap.Round)
}

/** Stand-in: Enhanced KYC has no icon of its own yet. */
@Composable
fun ProductMarkGlyph(tint: Color, size: Dp = SmileDimens.sizeIconMd) = Canvas(Modifier.size(size)) {
    val s = stroke()
    val w = this.size.width
    val corner = w * 0.22f
    drawRoundRect(
        color = tint,
        topLeft = Offset(w * 0.16f, w * 0.16f),
        size = Size(w * 0.68f, w * 0.68f),
        cornerRadius = CornerRadius(corner, corner),
        style = s,
    )
    drawLine(tint, Offset(w * 0.34f, w * 0.5f), Offset(w * 0.66f, w * 0.5f), s.width, StrokeCap.Round)
}

private fun DrawScope.stroke() = Stroke(
    width = SmileDimens.borderWidthThin.toPx(),
    cap = StrokeCap.Round,
    join = StrokeJoin.Round,
)
