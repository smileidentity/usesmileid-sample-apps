import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The profile store, whose only two hard rules are the starter's emptiness and the initials.
void main() {
  group('a launch with no arguments', () {
    test('starts from one empty starter, never the fixtures', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();

      expect(profiles.all, hasLength(1));
      expect(
        profiles.active.organisation,
        UseSmileIDSampleProfiles.starterOrganisation,
      );
      expect(profiles.active.person, isEmpty);
    });

    test('says so under the organisation until details are saved', () {
      expect(UseSmileIDSampleProfiles().active.caption, 'No user details yet');
    });
  });

  test('seedProfiles is the only way to the design three', () {
    expect(
      UseSmileIDSampleProfiles.forLaunch(
        const UseSmileIDSampleLaunchArgs(),
      ).all,
      hasLength(1),
    );
    expect(
      UseSmileIDSampleProfiles.forLaunch(
        const UseSmileIDSampleLaunchArgs(seedProfiles: true),
      ).all,
      hasLength(3),
    );
  });

  group('initials', () {
    String initialsFor({
      required String organisation,
      required String person,
    }) => UseSmileIDSampleProfile(
      id: 'p-1',
      organisation: organisation,
      person: person,
    ).initials;

    test('come from the person when there is one', () {
      expect(
        initialsFor(organisation: 'UpTech Finance', person: 'Kwame Asante'),
        'KA',
      );
    });

    test('fall back to the organisation for a profile naming nobody', () {
      expect(initialsFor(organisation: 'Default profile', person: ''), 'DP');
    });

    test('take at most two words, so a long name does not grow the avatar', () {
      expect(
        initialsFor(organisation: 'x', person: 'Ada Grace Byron King'),
        'AG',
      );
    });

    test('are a question mark when there is nothing to take', () {
      expect(initialsFor(organisation: '   ', person: ''), '?');
    });
  });

  group('the store', () {
    test('refuses an empty seed, rather than failing at the first read', () {
      expect(
        () => UseSmileIDSampleProfiles(<UseSmileIDSampleProfile>[]),
        throwsArgumentError,
      );
    });

    test('switches to a profile it holds and ignores one it does not', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
      );

      profiles.setActive('p-3');
      expect(profiles.active.organisation, 'PesaLink');
      expect(profiles.activeIndex, 2);

      profiles.setActive('p-99');
      expect(profiles.active.organisation, 'PesaLink');
    });

    // A duplicate key doubles a test id, which is why the id is the first FREE one rather than
    // one derived from the count.
    test('never reissues an id a removed position would have freed', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
      );

      expect(profiles.add(organisation: 'Fourth', person: '').id, 'p-4');
      expect(profiles.add(organisation: 'Fifth', person: '').id, 'p-5');
      expect(
        profiles.all.map((UseSmileIDSampleProfile p) => p.id).toSet(),
        hasLength(profiles.all.length),
      );
    });

    test('marks the profile it just created until that is cleared', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();
      expect(profiles.lastCreatedId, isNull);

      profiles.add(organisation: 'New', person: '');
      expect(profiles.lastCreatedId, 'p-2');

      profiles.clearLastCreated();
      expect(profiles.lastCreatedId, isNull);
    });
  });

  group('saved details', () {
    test('name the starter, which until then names nobody', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();

      profiles.setDefaults(
        'p-1',
        const UseSmileIDSampleUserDetails(
          firstName: 'Ada',
          lastName: 'Lovelace',
        ),
      );

      expect(profiles.active.person, 'Ada Lovelace');
      expect(profiles.active.initials, 'AL');
    });

    test('leave a created profile the name its sheet gave it', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
      );

      profiles.setDefaults(
        'p-1',
        const UseSmileIDSampleUserDetails(
          firstName: 'Someone',
          lastName: 'Else',
        ),
      );

      expect(profiles.find('p-1')!.person, 'Kwame Asante');
      expect(profiles.find('p-1')!.defaults.firstName, 'Someone');
    });

    test('are incomplete until both names are there', () {
      expect(const UseSmileIDSampleUserDetails().isComplete, isFalse);
      expect(
        const UseSmileIDSampleUserDetails(firstName: 'Ada').isComplete,
        isFalse,
      );
      expect(
        const UseSmileIDSampleUserDetails(
          firstName: 'Ada',
          lastName: 'Lovelace',
        ).isComplete,
        isTrue,
      );
    });
  });

  group('a callback URL', () {
    test('starts empty, which is the partner portal default', () {
      expect(UseSmileIDSampleProfiles().active.callbackUrl, isEmpty);
    });

    test('is stored with the details when the page edited it', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();
      profiles.setDefaults(
        'p-1',
        const UseSmileIDSampleUserDetails(firstName: 'Ada'),
        callbackUrl: 'https://kobo.example/hooks',
      );
      expect(profiles.active.callbackUrl, 'https://kobo.example/hooks');
    });

    test('is left alone by a save that did not edit it', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();
      profiles.setDefaults(
        'p-1',
        const UseSmileIDSampleUserDetails(),
        callbackUrl: 'https://kobo.example/hooks',
      );
      profiles.setDefaults(
        'p-1',
        const UseSmileIDSampleUserDetails(firstName: 'Ada'),
      );
      expect(profiles.active.callbackUrl, 'https://kobo.example/hooks');
    });
  });
}
