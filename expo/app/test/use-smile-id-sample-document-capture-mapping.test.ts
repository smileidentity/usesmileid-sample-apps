import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { DocumentCaptureMode, DocumentType } from '@smileid/usesmileid';
import {
  UseSmileIDSampleCaptureMode,
  smileIDSampleAspectRatios,
  smileIDSampleGenericDocumentDefaults,
  smileIDSampleIdDetailsDefaults,
  type UseSmileIDSampleAspectRatio,
  type UseSmileIDSampleCaptureAs,
  type UseSmileIDSampleDocumentOrientation,
  type UseSmileIDSampleIdDetails,
} from '@smileid/sample-ui';

import {
  smileIDSampleCaptureModeFor,
  smileIDSampleDocumentTypeFor,
} from '../src/flow/use-smile-id-sample-flow-builder-config';

type Case = {
  name: string;
  captureAs: UseSmileIDSampleCaptureAs;
  document: { code: string; subType?: string; name: string; hasBack: boolean; format: number };
  genericDocument?: {
    displayName: string;
    hasBackSide: boolean;
    orientation: UseSmileIDSampleDocumentOrientation;
    aspectRatio: UseSmileIDSampleAspectRatio;
  };
  expected: {
    documentType: string;
    displayName?: string;
    hasBackSide?: boolean;
    orientation?: string;
    knownAspectRatio?: number;
  };
};

const captureAs = (
  JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'spec', 'catalogue-rules.json'), 'utf8')) as {
    captureAs: { cases: Case[]; aspectRatios: Record<string, number | null> };
  }
).captureAs;

const detailsOf = (c: Case): UseSmileIDSampleIdDetails => ({
  ...smileIDSampleIdDetailsDefaults,
  country: { code: 'ZA', name: 'South Africa' },
  document: { ...c.document, subType: c.document.subType ?? null },
  captureAs: c.captureAs,
  genericDocument: c.genericDocument ?? smileIDSampleGenericDocumentDefaults,
});

/// spec/catalogue-rules.json captureAs: what "Capture as" hands the SDK.
describe('capture as', () => {
  it.each(captureAs.cases.map((c) => [c.name, c] as const))('%s', (_, c) => {
    const type = smileIDSampleDocumentTypeFor(detailsOf(c));
    if (c.expected.documentType === 'passport') expect(type).toEqual(DocumentType.Passport);
    else if (c.expected.documentType === 'greenBook') expect(type).toEqual(DocumentType.SouthAfricaGreenBook);
    else {
      expect(type.kind).toBe('genericDocument');
      expect(type.displayName).toBe(c.expected.displayName);
      expect(type.hasBackSide).toBe(c.expected.hasBackSide);
      if (c.expected.orientation) expect(type.orientation.toLowerCase()).toBe(c.expected.orientation);
      if (c.expected.knownAspectRatio !== undefined) expect(type.knownAspectRatio).toBeCloseTo(c.expected.knownAspectRatio);
    }
  });

  it('has the spec\'s cases and aspect ratios', () => {
    expect(captureAs.cases.length).toBeGreaterThanOrEqual(6);
    for (const ratio of smileIDSampleAspectRatios) expect(ratio.ratio).toBe(captureAs.aspectRatios[ratio.id] ?? null);
  });

  it('maps the three capture modes onto the SDK', () => {
    expect(smileIDSampleCaptureModeFor(UseSmileIDSampleCaptureMode.Auto)).toEqual(DocumentCaptureMode.AutoCapture);
    expect(smileIDSampleCaptureModeFor(UseSmileIDSampleCaptureMode.Manual)).toEqual(DocumentCaptureMode.ManualCapture);
    expect(smileIDSampleCaptureModeFor(UseSmileIDSampleCaptureMode.AutoWithFallback)).toEqual(
      DocumentCaptureMode.AutoCaptureWithManualFallback(),
    );
  });
});
