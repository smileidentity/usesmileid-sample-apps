import { smileIDSampleRemovalNotice } from '../src/model/use-smile-id-sample-removal-notice';
import {
  smileIDSampleProducts,
  smileIDSampleProductsOf,
} from '../src/model/use-smile-id-sample-product';
import {
  smileIDSampleFlowRoutes,
  smileIDSampleScenarios,
  smileIDSampleThemeScenarios,
} from '../src/model/use-smile-id-sample-scenario';
import { spec } from './spec-file';

type Scenarios = {
  scenarios: { id: string; kind: string; label: string }[];
  products: {
    sections: {
      section: string;
      items: {
        id: string;
        label: string;
        cardTitle: string;
        cardFamily: string;
        capture: boolean;
        needsIdDetails: boolean;
      }[];
    }[];
  };
};

const scenariosSpec = spec<Scenarios>('scenarios.json');

describe('flow scenarios match spec/scenarios.json', () => {
  const specFlow = scenariosSpec.scenarios.filter((s) => s.kind === 'flow');

  it('declares every flow scenario, in the spec order', () => {
    expect(smileIDSampleScenarios.map((s) => s.id)).toEqual(specFlow.map((s) => s.id));
  });

  it('uses the spec label for every flow scenario', () => {
    expect(smileIDSampleScenarios.map((s) => s.label)).toEqual(specFlow.map((s) => s.label));
  });
});

describe('theme scenarios match spec/scenarios.json', () => {
  const specThemes = scenariosSpec.scenarios.filter((s) => s.kind === 'theme');

  it('declares every theme scenario, in the spec order', () => {
    expect(smileIDSampleThemeScenarios.map((s) => s.id)).toEqual(specThemes.map((s) => s.id));
  });

  it('uses the spec label for every theme scenario', () => {
    expect(smileIDSampleThemeScenarios.map((s) => s.label)).toEqual(specThemes.map((s) => s.label));
  });
});

describe('products match spec/scenarios.json', () => {
  const specProducts = scenariosSpec.products.sections.flatMap((section) => section.items);

  it('declares every product, in design order', () => {
    expect(smileIDSampleProducts.map((p) => p.id)).toEqual(specProducts.map((p) => p.id));
  });

  it('carries the spec label, card title and card family for each', () => {
    expect(
      smileIDSampleProducts.map((p) => [p.id, p.label, p.cardTitle, p.cardFamily]),
    ).toEqual(specProducts.map((p) => [p.id, p.label, p.cardTitle, p.cardFamily]));
  });

  it('carries the spec capture and id-details flags for each', () => {
    expect(smileIDSampleProducts.map((p) => [p.id, p.capture, p.needsIdDetails])).toEqual(
      specProducts.map((p) => [p.id, p.capture, p.needsIdDetails]),
    );
  });

  it('groups the products into the two spec sections', () => {
    const specSections = scenariosSpec.products.sections;
    expect(smileIDSampleProductsOf('Authentication').map((p) => p.id)).toEqual(
      specSections[0]?.items.map((p) => p.id),
    );
    expect(smileIDSampleProductsOf('Verifications').map((p) => p.id)).toEqual(
      specSections[1]?.items.map((p) => p.id),
    );
  });

  it('is the one captureless product that proves a flow composes without capture()', () => {
    expect(smileIDSampleProducts.filter((p) => !p.capture).map((p) => p.id)).toEqual(['enhancedKyc']);
  });
});

describe('flow routes match the result card schema', () => {
  type ResultCard = { properties: { route: { enum: string[] } } };

  it('offers exactly the two presentations the card can report', () => {
    const schema = spec<ResultCard>('result-card.schema.json');
    expect([...smileIDSampleFlowRoutes]).toEqual(schema.properties.route.enum);
  });
});

describe('the removal notice copy', () => {
  it('is singular for one and plural for more, from the shared package', () => {
    expect(smileIDSampleRemovalNotice(1).message).toBe('1 verification removed');
    expect(smileIDSampleRemovalNotice(3).message).toBe('3 verifications removed');
    expect(smileIDSampleRemovalNotice(2).actionLabel).toBe('Undo');
  });
});
