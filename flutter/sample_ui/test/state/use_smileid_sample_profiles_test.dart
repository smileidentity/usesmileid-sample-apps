import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  const UseSmileIDSampleUserDetails ada = UseSmileIDSampleUserDetails(
    firstName: 'Ada',
    lastName: 'Okafor',
    email: 'ada@kobo.example',
  );

  UseSmileIDSampleProfile profile({
    String id = 'p-1',
    String organisation = 'UpTech Finance',
    String first = '',
    String last = '',
  }) => UseSmileIDSampleProfile(
    id: id,
    organisation: organisation,
    defaults: UseSmileIDSampleUserDetails(firstName: first, lastName: last),
  );

  test('a plain launch has no profile', () {
    final UseSmileIDSampleProfiles profiles =
        UseSmileIDSampleProfiles.forLaunch(
          const UseSmileIDSampleLaunchArgs(),
          stored: UseSmileIDSampleProfiles(),
        );

    expect(profiles.all, isEmpty);
    expect(profiles.active, isNull);
    expect(profiles.partnerName, 'Smile ID');
    expect(profiles.partnerId, 'p-1');
  });

  test('a seeded launch shows the fixtures over what was stored', () {
    final UseSmileIDSampleProfiles stored = UseSmileIDSampleProfiles(
      <UseSmileIDSampleProfile>[profile(organisation: 'Kobo Bank')],
    );

    expect(
      UseSmileIDSampleProfiles.forLaunch(
        const UseSmileIDSampleLaunchArgs(seedProfiles: true),
        stored: stored,
      ).all,
      UseSmileIDSampleProfiles.fixtures(),
    );
    expect(
      UseSmileIDSampleProfiles.forLaunch(
        const UseSmileIDSampleLaunchArgs(),
        stored: stored,
      ),
      same(stored),
    );
  });

  group('initials', () {
    test('come from the person, then the organisation', () {
      expect(profile(first: 'Kwame', last: 'Asante').initials, 'KA');
      expect(profile(first: 'Mary Anne', last: 'Smith').initials, 'MA');
      expect(profile(organisation: 'PesaLink').initials, 'P');
      expect(profile(organisation: '').initials, '?');
    });
  });

  test(
    'the first profile becomes active and later ones wait for the offer',
    () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();

      final UseSmileIDSampleProfile first = profiles.add(
        organisation: 'Karibu Pay',
      );
      expect(profiles.activeId, first.id);
      expect(profiles.lastCreatedId, isNull);

      final UseSmileIDSampleProfile second = profiles.add(
        organisation: 'Sahara Pay',
      );
      expect(profiles.activeId, first.id);
      expect(profiles.lastCreatedId, second.id);
      expect(profiles.all.map((UseSmileIDSampleProfile p) => p.id), <String>[
        'p-1',
        'p-2',
      ]);
    },
  );

  test('ids skip ones already taken', () {
    final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
      <UseSmileIDSampleProfile>[
        profile(),
        profile(id: 'p-3'),
        profile(id: 'p-4'),
      ],
    );

    expect(profiles.add(organisation: 'Acme').id, 'p-5');
    expect(profiles.add(organisation: 'Beta').id, 'p-6');
  });

  test('a blank organisation names the app on consent, never the person', () {
    final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles()
      ..add(organisation: '', defaults: ada);

    expect(profiles.active?.title, 'Ada Okafor');
    expect(profiles.partnerName, 'Smile ID');
  });

  test('an update leaves what it was not given', () {
    final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles();
    final UseSmileIDSampleProfile created = profiles.add(
      organisation: 'Karibu Pay',
    );
    profiles.update(created.id, callbackUrl: ' https://partner.example/hook ');

    profiles.update(created.id, defaults: ada);

    expect(profiles.active?.callbackUrl, 'https://partner.example/hook');
    expect(profiles.active?.organisation, 'Karibu Pay');
    expect(profiles.active?.person, 'Ada Okafor');
  });

  test(
    'deleting the active profile hands over to the first left, then to none',
    () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
        'p-2',
      );

      profiles.delete('p-2');
      expect(profiles.activeId, 'p-1');

      profiles
        ..delete('p-1')
        ..delete('p-3');
      expect(profiles.activeId, isNull);
    },
  );

  test('sign out clears every profile', () {
    final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
      UseSmileIDSampleProfiles.fixtures(),
    )..clear();

    expect(profiles.all, isEmpty);
    expect(profiles.active, isNull);
  });

  test('a stored active id that names no profile falls back to the first', () {
    expect(
      UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
        'p-9',
      ).activeId,
      'p-1',
    );
  });

  group('keep', () {
    test('the first run creates an active profile from what was typed', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles()
        ..keep(ada, organisation: ' Kobo Bank ');

      expect(profiles.active?.organisation, 'Kobo Bank');
      expect(profiles.active?.defaults, ada);
    });

    test('an active profile takes the edits', () {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
      )..keep(ada, organisation: '');

      expect(profiles.find('p-1')?.defaults, ada);
      expect(profiles.find('p-1')?.organisation, 'UpTech Finance');
      expect(profiles.all, hasLength(3));
    });

    test('a field the token supplies is never stored', () {
      final UseSmileIDSampleProfiles profiles =
          UseSmileIDSampleProfiles(<UseSmileIDSampleProfile>[
            profile(organisation: 'UpTech', first: 'Kwame', last: 'Asante'),
          ])..keep(
            const UseSmileIDSampleUserDetails(email: 'ada@kobo.example'),
            organisation: '',
            requirement: const UseSmileIDSampleUserDetailsRequirement(
              firstName: false,
              lastName: false,
            ),
          );

      expect(
        profiles.active?.defaults,
        const UseSmileIDSampleUserDetails(
          firstName: 'Kwame',
          lastName: 'Asante',
          email: 'ada@kobo.example',
        ),
      );
    });
  });

  group('the stored record', () {
    test('round-trips, including characters JSON escapes', () {
      final UseSmileIDSampleProfiles profiles =
          UseSmileIDSampleProfiles(<UseSmileIDSampleProfile>[
            const UseSmileIDSampleProfile(
              id: 'p-1',
              organisation: 'Kobo "Bank" \\ Ltd\n',
              defaults: UseSmileIDSampleUserDetails(
                firstName: 'Adá',
                lastName: "O'Neil",
                email: 'ada@kobo.example',
                phone: '+254 700',
              ),
              callbackUrl: 'https://kobo.example/hook?a=1&b=2',
            ),
            const UseSmileIDSampleProfile(id: 'p-2', organisation: ''),
          ], 'p-2');

      final UseSmileIDSampleProfiles decoded =
          UseSmileIDSampleProfilesCodec.decode(
            UseSmileIDSampleProfilesCodec.encode(profiles),
          );

      expect(decoded.all, profiles.all);
      expect(decoded.activeId, 'p-2');
    });

    test('anything unreadable is no profiles', () {
      for (final String? text in <String?>[
        null,
        '',
        'not json',
        '[]',
        '{"profiles":[{"id":"p-1"}]}',
        '{"version":2,"profiles":[{"id":"p-1"}]}',
        '{"version":1,"profiles":"p-1"}',
        '{"version":1,"profiles":[{"id":"p-1","organisation":"Kobo"',
      ]) {
        expect(
          UseSmileIDSampleProfilesCodec.decode(text).all,
          isEmpty,
          reason: text,
        );
      }
    });

    test('a profile without an id, or with a repeated one, is dropped', () {
      final UseSmileIDSampleProfiles
      decoded = UseSmileIDSampleProfilesCodec.decode(
        '{"version":1,"activeId":"p-1","profiles":[{"organisation":"No id"},'
        '{"id":"p-1","organisation":"First"},{"id":"p-1","organisation":"Again"}]}',
      );

      expect(
        decoded.all.map((UseSmileIDSampleProfile p) => p.organisation),
        <String>['First'],
      );
    });

    test('reads the shape the other three apps write', () {
      final UseSmileIDSampleProfiles
      decoded = UseSmileIDSampleProfilesCodec.decode(
        '{"version":1,"activeId":"p-1","profiles":[{"id":"p-1","organisation":"Kobo",'
        '"firstName":"Ada","lastName":"","email":"","phone":"","callbackUrl":""}]}',
      );

      expect(decoded.active?.organisation, 'Kobo');
      expect(decoded.active?.defaults.firstName, 'Ada');
    });
  });
}
