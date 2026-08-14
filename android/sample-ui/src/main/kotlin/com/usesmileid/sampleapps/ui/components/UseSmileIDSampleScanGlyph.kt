package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The corner-bracket mark on the Scan token screen. [sweep] keeps the design's hidden reticle reachable for a live camera. */
@Composable
fun UseSmileIDSampleScanGlyph(
    modifier: Modifier = Modifier,
    size: Dp = SmileDimens.space64 * 4,
    sweep: Boolean = false,
) {
    val bracket = UseSmileIDSampleTheme.colors.primary
    val line = UseSmileIDSampleTheme.colors.textMuted
    Canvas(modifier = modifier.size(size)) {
        val stroke = Stroke(
            width = SmileDimens.borderWidthThick.toPx(),
            cap = StrokeCap.Round,
            join = StrokeJoin.Round,
        )
        val side = this.size.minDimension
        val arm = side * 0.17f
        val inset = side * 0.06f
        val far = side - inset

        listOf(
            Triple(Offset(inset, inset + arm), Offset(inset, inset), Offset(inset + arm, inset)),
            Triple(Offset(far - arm, inset), Offset(far, inset), Offset(far, inset + arm)),
            Triple(Offset(far, far - arm), Offset(far, far), Offset(far - arm, far)),
            Triple(Offset(inset + arm, far), Offset(inset, far), Offset(inset, far - arm)),
        ).forEach { (from, corner, to) ->
            drawPath(
                path = Path().apply {
                    moveTo(from.x, from.y)
                    lineTo(corner.x, corner.y)
                    lineTo(to.x, to.y)
                },
                color = bracket,
                style = stroke,
            )
        }

        if (sweep) {
            val midY = side / 2f
            drawLine(
                color = line,
                start = Offset(inset + arm, midY),
                end = Offset(far - arm, midY),
                strokeWidth = stroke.width,
                cap = StrokeCap.Round,
            )
        }
    }
}
