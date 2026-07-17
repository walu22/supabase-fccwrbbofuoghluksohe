-- Seed data for TumaHelper (local development / db reset)
-- Contains only non-sensitive reference/catalog data: service areas,
-- estates, the services catalog, promo codes, and demo helper profiles.
-- No customer PII (auth users, profiles, bookings, messages, etc.) is included.

-- Service areas in Lusaka
COPY "public"."lusaka_areas" ("id", "name", "travel_fee", "created_at") FROM stdin;
b146afb5-09b2-4948-98fe-86d07a62a8bf	Kabulonga	25	2026-05-15 09:40:32.136446+00
f6f63f66-05f0-42de-acab-551f21e22158	Rhodes Park	25	2026-05-31 23:14:08.346583+00
4eaf2159-0ba2-4830-ac62-ec3a69fe2d7e	Libala	25	2026-05-31 23:14:08.919938+00
2c682934-0961-4a2b-85f1-eaa959074fd4	Olympia	45	2026-05-15 09:40:32.136446+00
59d8619d-d5ed-40d2-9a02-95cfd7b61ab2	Foxdale	45	2026-05-31 23:14:09.761181+00
66865dab-3383-41df-b6f9-925a74a2c9e6	Chainda	45	2026-05-31 23:14:10.319589+00
f8f22480-b980-4f21-b733-c32047a538b1	Leopards Hill	25	2026-05-31 23:14:12.892713+00
e899bad6-9b39-460d-b544-f6afa3886261	Ibex Hill	25	2026-05-31 23:14:13.886194+00
174393de-a3f4-4444-b0df-ac4256cf7435	Longacres	0	2026-05-31 23:14:15.14647+00
4f9cc640-d2d6-4ef0-b49a-efa66c821a23	Woodlands	0	2026-05-15 09:40:32.136446+00
daf2d966-e655-4ee5-9c02-cd00edd75769	Roma	0	2026-05-15 09:40:32.136446+00
d471f944-5242-43ef-b167-df902ccd10a0	Kalundu	0	2026-05-31 23:14:17.008018+00
c6444c80-7e44-4272-acbd-d33ea1ac180a	Fairview	0	2026-05-31 23:14:17.575849+00
97c6df9a-ce72-4376-b9ea-f8efabf02388	Thorn Park	0	2026-05-31 23:14:18.121649+00
694cb844-d443-4a78-924c-435932d2091e	Showgrounds	0	2026-05-31 23:14:18.666571+00
ad1f9513-5169-4358-8084-3c1dea0ee164	Chilenje	30	2026-05-31 23:14:19.213228+00
5dd491c9-9144-4bbf-9036-639100cfc682	Libala South	45	2026-05-31 23:14:19.758479+00
a982fd93-f809-4fe1-9334-87d84ef30e66	Kamwala	30	2026-05-31 23:14:20.317233+00
1d63f9da-1719-4699-8274-8b3bd88cb491	Kamwala South	45	2026-05-31 23:14:20.859607+00
40104794-8e9b-4507-b13e-7ce6b2a2d0e1	Ng'ombe	45	2026-05-31 23:14:21.410574+00
dd16b8ee-b49f-41e8-a6af-aeec8ce90071	PHI	45	2026-05-31 23:14:21.954709+00
131268c6-6310-4cfe-80d9-be40899e8555	Chawama	45	2026-05-31 23:14:22.506438+00
10944a9d-12d2-40a1-907e-4be904025b15	John Laing	45	2026-05-31 23:14:23.053909+00
34d0858c-04e9-4f3b-9f98-571653439606	Chelstone	30	2026-05-31 23:14:23.603789+00
1eafa21e-ae91-418c-89ca-e5b6dc3cf7f0	Avondale	30	2026-05-31 23:14:24.150862+00
3008ccfa-fde8-4fba-98ea-c1aa940d9a84	Northmead	30	2026-05-31 23:14:24.695229+00
86f354be-3b81-4fa6-9542-ca5a4c4c8a4c	Kalingalinga	45	2026-05-31 23:14:25.236942+00
b2e40f1b-be3a-4bb7-9e47-17fbfd05c6ef	Chaisa	45	2026-05-31 23:14:25.78881+00
06959363-488b-40e1-9bae-983c9a6546e9	Matero	45	2026-05-31 23:14:26.335984+00
9e402f43-758a-4ba7-9e29-2892e7692d3f	George	45	2026-05-31 23:14:26.882412+00
dca46b59-d332-4b68-b04f-98e56c2941f4	Emmasdale	45	2026-05-31 23:14:27.422056+00
285b9997-7a36-4cf7-a372-1691d759da06	Mandevu	45	2026-05-31 23:14:27.965316+00
aa115fad-1574-409a-8ed1-058d113d6117	Chalala	30	2026-05-15 09:40:32.136446+00
f9089b00-f680-48b0-a2e3-f61fa7d23acb	Nyumba Yanga	30	2026-05-31 23:14:28.795178+00
02afd2c5-25fa-4edf-acb9-75af63875e9c	Makeni	30	2026-05-31 23:14:29.337755+00
2a3731c5-ea57-4fdb-9226-b7777c15554d	Bauleni	45	2026-05-31 23:14:29.881742+00
c957b994-63d1-4874-b496-0f6f486252d8	Silverest	45	2026-05-31 23:14:30.425674+00
201f434c-b7f0-433f-aeb6-1fc8358a7b46	Batoka	45	2026-05-31 23:14:30.97413+00
59c3ea3c-814d-41d2-9efd-1f6e1ca5aebf	Ngwerere	45	2026-05-31 23:14:31.519405+00
2201f244-29f7-46b3-a326-431508bfac9e	Garden Park	45	2026-05-31 23:14:32.0616+00
a36a77de-c279-4dab-80e4-1cd4ebf9fd61	Meanwood	0	2026-05-31 23:14:32.607309+00
7f851253-149c-4d04-ac32-1ddba935ced3	Eaglesvale	45	2026-05-31 23:14:33.146975+00
0f2ac5ca-1d30-49c3-97bb-e516a612d18f	Mass Media	45	2026-05-31 23:14:33.717367+00
e6be5434-c01f-4422-bbdc-254a21da7108	Sunningdale	45	2026-05-31 23:14:34.265029+00
9217daf2-03d4-459f-8337-edbe9acffb4b	Barlastone	45	2026-05-31 23:14:34.811267+00
d0092d89-7a04-4c2e-9dbb-3cb07a03f299	Kabanana	45	2026-05-31 23:14:35.356001+00
089c0766-480c-4f49-8aee-0010f5c8e8dc	Mutendere	45	2026-05-31 23:14:35.896795+00
b1e89b3d-8fcc-4af6-9854-4aaf98b3ca89	Rhodesview	45	2026-05-31 23:14:36.43776+00
\.

-- Estates within each service area
COPY "public"."lusaka_estates" ("id", "area_id", "name", "is_active", "created_at") FROM stdin;
8721db56-1188-44dd-9904-a8cdc1d5e261	b146afb5-09b2-4948-98fe-86d07a62a8bf	Kabulonga Gardens	t	2026-05-18 12:54:28.143977+00
ea5af5e2-2580-4314-afe1-c5a02d47456c	b146afb5-09b2-4948-98fe-86d07a62a8bf	Sunny Garden Estate	t	2026-05-18 12:54:28.143977+00
edda09ab-d29b-4d08-ac28-cb72f42abe27	b146afb5-09b2-4948-98fe-86d07a62a8bf	Kabulonga View Apartments	t	2026-05-18 12:54:28.143977+00
411abeeb-1b93-4dee-a951-d1fb49fd7690	b146afb5-09b2-4948-98fe-86d07a62a8bf	The Palms	t	2026-05-18 12:54:28.143977+00
2ef40e79-7d07-4b85-812f-6304feb30fdd	4f9cc640-d2d6-4ef0-b49a-efa66c821a23	Woodlands Extension	t	2026-05-18 12:54:28.143977+00
959ece05-3ffd-449a-ac4f-e6a5671ab728	4f9cc640-d2d6-4ef0-b49a-efa66c821a23	Garden City	t	2026-05-18 12:54:28.143977+00
a6d5dd8b-8152-441c-a8cd-b58c8c39aef5	4f9cc640-d2d6-4ef0-b49a-efa66c821a23	Woodlands Heights	t	2026-05-18 12:54:28.143977+00
e76bd40c-09fc-4b34-8ff9-a1daba9bba7d	daf2d966-e655-4ee5-9c02-cd00edd75769	Roma Park	t	2026-05-18 12:54:28.143977+00
a81b132f-3d30-4b74-ad09-b97512bc9f1a	daf2d966-e655-4ee5-9c02-cd00edd75769	Foxdale Court	t	2026-05-18 12:54:28.143977+00
c091d376-9f40-41b8-b950-e0e32f4e7b82	daf2d966-e655-4ee5-9c02-cd00edd75769	Roma Gardens	t	2026-05-18 12:54:28.143977+00
7b9d673f-b09a-4501-98fc-2f07ae1dfed3	aa115fad-1574-409a-8ed1-058d113d6117	Silverest Gardens	t	2026-05-18 12:54:28.143977+00
5904d9dd-c0c4-4852-bc66-4e51f9cd5bc0	aa115fad-1574-409a-8ed1-058d113d6117	Chalala Estate	t	2026-05-18 12:54:28.143977+00
4f9f4896-f052-4ab2-bfe8-32c9afbdf7db	aa115fad-1574-409a-8ed1-058d113d6117	Twin Palms	t	2026-05-18 12:54:28.143977+00
ac8ae26d-a8a0-4a8e-8f04-4744770dcfbb	b146afb5-09b2-4948-98fe-86d07a62a8bf	Kabulonga Courts	t	2026-05-31 23:14:37.090868+00
e9a2ade0-a25d-461c-8fb8-07e16d7091bf	b146afb5-09b2-4948-98fe-86d07a62a8bf	Sable Road	t	2026-05-31 23:14:37.73622+00
2ce1520f-b045-4abc-90fe-53f9990c2367	f6f63f66-05f0-42de-acab-551f21e22158	Rhodes Park Heights	t	2026-05-31 23:14:38.285219+00
12dfa7c8-d2d3-49ee-9732-e9c639aa730e	4eaf2159-0ba2-4830-ac62-ec3a69fe2d7e	Libala Green	t	2026-05-31 23:14:38.846249+00
88ec4566-76aa-444f-81a4-08b8f907887c	2c682934-0961-4a2b-85f1-eaa959074fd4	Olympia Park	t	2026-05-31 23:14:39.392697+00
fd461e73-20cf-47e1-81d9-85d85e1824a1	4f9cc640-d2d6-4ef0-b49a-efa66c821a23	Woodlands Chambers	t	2026-05-31 23:14:40.214098+00
f29cbd87-9cb9-41c6-8aba-9897c71932ec	174393de-a3f4-4444-b0df-ac4256cf7435	Longacres Gardens	t	2026-05-31 23:14:41.023583+00
3ab7cf3e-0d06-4106-b68e-567654782c6c	e899bad6-9b39-460d-b544-f6afa3886261	Ibex Hill Estate	t	2026-05-31 23:14:41.56593+00
7bd5be63-3e40-4724-b1d5-56dbb3645a7b	f8f22480-b980-4f21-b733-c32047a538b1	Leopards Hill Lodge Area	t	2026-05-31 23:14:42.111187+00
144e08c7-0f7c-4534-b6fc-bd7f8595ac48	a36a77de-c279-4dab-80e4-1cd4ebf9fd61	Meanwood Valley	t	2026-05-31 23:14:42.656342+00
788dfa4a-c449-46db-ab4c-2d9be10b6c9a	ad1f9513-5169-4358-8084-3c1dea0ee164	Chilenje South	t	2026-05-31 23:14:43.205159+00
2db5b31f-92b8-4f54-8314-f30220259a44	a982fd93-f809-4fe1-9334-87d84ef30e66	Kamwala Central	t	2026-05-31 23:14:43.749676+00
d350de24-df89-40cb-bce1-b3813e2e1e74	34d0858c-04e9-4f3b-9f98-571653439606	Chelstone Green	t	2026-05-31 23:14:44.300384+00
3a174f63-e620-4518-9fe0-b9927d322170	1eafa21e-ae91-418c-89ca-e5b6dc3cf7f0	Avondale Park	t	2026-05-31 23:14:44.842595+00
6db41f89-418a-4837-939a-1a4dd5007bbc	3008ccfa-fde8-4fba-98ea-c1aa940d9a84	Northmead Court	t	2026-05-31 23:14:48.195649+00
5fc9646e-5880-456c-a3cf-4d7eb3ebeccc	aa115fad-1574-409a-8ed1-058d113d6117	Chalala North	t	2026-05-31 23:14:49.932812+00
0ce03093-89b5-41b9-b918-ebf39545bf14	aa115fad-1574-409a-8ed1-058d113d6117	Chalala South	t	2026-05-31 23:14:50.854121+00
d9f60dad-2764-449c-98c0-ce1dad72675a	f9089b00-f680-48b0-a2e3-f61fa7d23acb	Nyumba Yanga Estate	t	2026-05-31 23:14:51.441093+00
bf92010d-5cf5-4b35-9c6c-e6eda5c474d6	02afd2c5-25fa-4edf-acb9-75af63875e9c	Makeni Villa	t	2026-05-31 23:14:51.98816+00
e095c25e-7949-4f5c-bf00-93bd3a39e598	c957b994-63d1-4874-b496-0f6f486252d8	Silverest Heights	t	2026-05-31 23:14:52.537251+00
d7d49daa-222b-47ab-ba86-1bb7738a5741	c6444c80-7e44-4272-acbd-d33ea1ac180a	Fairview Estate	t	2026-05-31 23:14:53.084871+00
875fe414-d311-4031-b283-0a9acddb4fa4	d471f944-5242-43ef-b167-df902ccd10a0	Kalundu Hills	t	2026-05-31 23:14:53.626605+00
cb287298-1aeb-45ab-a179-94add613a3ee	7f851253-149c-4d04-ac32-1ddba935ced3	Eaglesvale Estate	t	2026-05-31 23:14:54.166357+00
17f9ce5f-1e2a-4c44-8e85-6d586a2bde94	e6be5434-c01f-4422-bbdc-254a21da7108	Sunningdale Estate	t	2026-05-31 23:14:54.712626+00
46a8ac01-2ac3-4d78-ae51-11da0033cd51	86f354be-3b81-4fa6-9542-ca5a4c4c8a4c	Kalingalinga (near)	t	2026-05-31 23:14:55.253281+00
704b9bce-e9fc-408b-ba68-6334ac9c7a85	dca46b59-d332-4b68-b04f-98e56c2941f4	Emmasdale Estate	t	2026-05-31 23:14:55.796489+00
0ab6fe38-2fe7-472c-810d-d6b2fedb5412	2201f244-29f7-46b3-a326-431508bfac9e	Garden Park Estate	t	2026-05-31 23:14:56.340221+00
\.

-- Services catalog
COPY "public"."services" ("id", "category", "name", "description", "hourly_rate", "estimated_duration", "tasks") FROM stdin;
standard-cleaning	cleaning	Standard Cleaning	Regular home cleaning and maintenance.	150.00	2-3 hours	{Dusting,Vacuuming,"Mopping floors","Bathroom cleaning","Kitchen cleaning"}
deep-cleaning	cleaning	Deep Cleaning	Thorough top-to-bottom cleaning.	250.00	4-6 hours	{Baseboards,"Ceiling fans","Inside cabinets","Behind appliances"}
move-in-out	cleaning	Move In/Out Cleaning	Complete cleaning for empty properties.	350.00	6-8 hours	{"Deep clean all rooms","Inside all appliances","Window cleaning"}
office-cleaning	cleaning	Office/Commercial Cleaning	Workplace cleaning and sanitation.	200.00	2-4 hours	{"Desk cleaning","Floor cleaning","Bathroom sanitization"}
braai-cleaning	cleaning	Braai Area Cleaning	Cleaning of braai stands and entertainment areas.	180.00	1-2 hours	{"Ash removal","Grid cleaning","Patio sweeping","Grease removal"}
dust-removal	cleaning	Dust & Sand Removal	Specialized cleaning after sandstorms/East Weather.	200.00	2-4 hours	{"Garage blowout","Window tracks","Patio spray down","Fine dust removal"}
general-repairs	handyman	General Home Repairs	Small repairs and fixes around the home.	200.00	2-3 hours	{"Fix leaky faucets","Door repairs","Cabinet fixes"}
electric-fence	handyman	Electric Fence Repairs	Maintenance of electric fencing.	350.00	1-3 hours	{"Strand repair","Insulator replacement","Energizer check"}
gate-motor	handyman	Gate Motor Services	Gate motor troubleshooting and repair.	400.00	1-2 hours	{"Battery replacement","Rack realignment",Programming}
solar-geyser	handyman	Solar Geyser Maintenance	Repair and service of solar water heaters.	450.00	2-4 hours	{"Element replacement","Leak repair","Panel flush"}
aircon-regas	handyman	Aircon Services	Cleaning and re-gassing of AC units.	350.00	1-2 hours	{"Filter cleaning","Gas refill","Leak check"}
lawn-care	gardening	Lawn Mowing & Care	Regular lawn maintenance.	150.00	1-2 hours	{"Lawn mowing",Edging,"Grass trimming"}
water-wise	gardening	Water-wise Garden Care	Maintenance of succulent and desert gardens.	180.00	2-3 hours	{"Succulent pruning","Gravel raking","Drip irrigation check"}
garden-cleanup	gardening	Garden Cleanup	One-time garden clearing.	250.00	3-5 hours	{"Overgrowth removal","Debris clearing","Leaf removal"}
moving-help	moving	Moving Help	Assistance with moving heavy items.	250.00	2-4 hours	{Loading,Unloading,"Heavy lifting"}
furniture-delivery	moving	Furniture Delivery	Pick up and deliver furniture.	300.00	2-4 hours	{Pickup,Transport,Delivery}
babysitting	childcare	Babysitting	Occasional childcare.	80.00	2-8 hours	{"Supervise children","Play activities","Meal preparation"}
tutoring	childcare	Tutoring	Academic support for students.	150.00	1-2 hours	{"Subject tutoring","Homework assistance"}
dstv-install	technology	DSTV & Satellite	Installation and signal fixing.	300.00	1-3 hours	{"Dish alignment","Decoder setup",Cabling}
wifi-networking	technology	WiFi Setup	Home network configuration.	250.00	1-2 hours	{"Router setup","Extender installation",Troubleshooting}
79eb322d-2a39-49be-bead-7885d674db64	gardening	Elite Gardening	Professional landscaping and lawn maintenance services for premium properties.	450.00	\N	\N
\.

-- Promotional codes
COPY "public"."promo_codes" ("id", "created_at", "code", "discount_percentage", "is_active", "valid_until") FROM stdin;
1b9a91fb-b81b-4426-ac50-7307c184d724	2026-05-16 20:59:26.519027+00	KIMI20	20	t	2026-12-31 23:59:59+00
6a428dc4-cc39-4a28-aab4-af5f5633a5bb	2026-05-16 20:59:26.519027+00	LUSAKA50	50	t	2026-12-31 23:59:59+00
18b6dc10-c573-43e9-93ab-31fd02b3b100	2026-05-16 20:59:26.519027+00	TEST10	10	t	2026-12-31 23:59:59+00
\.

-- Demo helper profiles
COPY "public"."helpers" ("id", "name", "rating", "jobs_completed", "avatar_url", "bio", "is_active", "created_at", "hourly_rate", "badges") FROM stdin;
ab09c1e5-f207-492b-ad54-e2187bfa83aa	Grace Mwanza	4.90	342	https://api.dicebear.com/7.x/avataaars/svg?seed=Grace	\N	t	2026-05-15 09:40:32.136446+00	55	{}
36dbcd97-3c94-44a3-a8f1-4d4f2b990c64	Esther Banda	4.80	218	https://api.dicebear.com/7.x/avataaars/svg?seed=Esther	\N	t	2026-05-15 09:40:32.136446+00	55	{}
01dd3b51-42aa-42f6-a600-04846f1d8191	Joseph Phiri	4.70	156	https://api.dicebear.com/7.x/avataaars/svg?seed=Joseph	\N	t	2026-05-15 09:40:32.136446+00	55	{}
d548c6d4-6865-4d24-b365-372729747467	Grace Lungu	4.90	128	https://images.unsplash.com/photo-1531123897727-8f129e16fd3c?w=400&h=400&fit=crop&crop=face	Dedicated domestic professional with 5 years across Lusaka's finest households.	t	2026-05-16 19:09:04.833711+00	55	{"Background Checked","NRC Verified","ID Verified","Top Rated"}
ea452d80-a836-433e-97b3-73725c0d63bb	Peter Banda	5.00	86	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=face	Facility management background. Meticulous, reliable, and always on time.	t	2026-05-16 19:09:04.833711+00	65	{"Background Checked","NRC Verified","ID Verified","Perfect Rating"}
c475ce0d-0a92-4c56-922d-95a4fb2a0c8e	Eunice Phiri	4.80	74	https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=400&h=400&fit=crop&crop=face	Laundry and ironing specialist. Fast, careful with delicates, and always warm.	t	2026-05-16 19:09:04.833711+00	45	{"Background Checked","NRC Verified","ID Verified"}
6f3e68bc-784b-4cf9-ab35-97c66037d67d	Chanda Mwale	4.70	61	https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop&crop=face	Indoor cleaning expert. Leaves every room spotless and smelling fresh.	t	2026-05-16 19:09:04.833711+00	50	{"Background Checked","NRC Verified"}
875ad344-5706-492d-82ad-72a33af80358	Mpho Zulu	4.90	95	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face	Deep cleaning specialist. No corner is too hard to reach.	t	2026-05-16 19:09:04.833711+00	60	{"Background Checked","NRC Verified","ID Verified","Top Rated"}
e935f312-19cf-4b92-95f2-5d24d8a44853	Thandiwe Mbewe	4.60	48	https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=400&h=400&fit=crop&crop=face	Airbnb turnover expert. Guests always rate her 5 stars for cleanliness.	t	2026-05-16 19:09:04.833711+00	55	{"Background Checked","NRC Verified"}
0e48c425-1816-43d0-bacb-a1d756dff8d3	Bwalya Mutale	4.80	83	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face	Outdoor and garden professional. Lawn, pool, and exterior care.	t	2026-05-16 19:09:04.833711+00	60	{"Background Checked","NRC Verified","ID Verified"}
2038eccb-05b6-49a4-99bc-45a36d0c9c8b	Mutale Kapasa	4.50	39	https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=400&fit=crop&crop=face	Office cleaning specialist. Quiet, efficient, and thorough.	t	2026-05-16 19:09:04.833711+00	50	{"Background Checked","NRC Verified"}
19860124-125d-4f3a-be5d-c91e77ec8975	Lovemore Daka	4.90	112	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face	Home repairs and maintenance. Plumbing, electrical, and general fixes.	t	2026-05-16 19:09:04.833711+00	80	{"Background Checked","NRC Verified","ID Verified","Top Rated"}
91a38e66-6130-44cc-a250-bc668b9c9e20	Nsofwa Nkutu	4.70	57	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop&crop=face	Moving and packing expert. Careful with valuables, fast, and professional.	t	2026-05-16 19:09:04.833711+00	70	{"Background Checked","NRC Verified"}
2d620ad0-520d-462f-b052-7b991c166ec5	Monde Sichali	4.80	66	https://images.unsplash.com/photo-1500336624523-d727130c3328?w=400&h=400&fit=crop&crop=face	Pet care specialist. Dog walking, feeding, and grooming services.	t	2026-05-16 19:09:04.833711+00	45	{"Background Checked","NRC Verified","ID Verified"}
c5201a11-1add-42cd-8791-57cefb772a78	Prisca Tembo	4.90	91	https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=400&h=400&fit=crop&crop=face	Full-service cleaning pro. Handles all domestic tasks with care and precision.	t	2026-05-16 19:09:04.833711+00	55	{"Background Checked","NRC Verified","ID Verified","Top Rated"}
00200cdd-91ff-417b-814c-2a91a223d7ea	Joseph Banda	4.60	44	https://images.unsplash.com/photo-1552058544-f2b08422138a?w=400&h=400&fit=crop&crop=face	Garden and outdoor enthusiast. Keeps compounds lush and well-maintained.	t	2026-05-16 19:09:04.833711+00	50	{"Background Checked","NRC Verified"}
9db9cb87-e6bd-4b08-8e02-113fee0b037e	Mulenga Chipata	4.70	72	https://images.unsplash.com/photo-1554151228-14d9def656e4?w=400&h=400&fit=crop&crop=face	Deep cleaning and kitchen specialist. Oven, fridge, and cabinet expert.	t	2026-05-16 19:09:04.833711+00	58	{"Background Checked","NRC Verified","ID Verified"}
1ad11b41-4663-4239-984c-a913a7c4fa56	Nakamba Mutale	4.80	59	https://images.unsplash.com/photo-1590086782957-93c06ef21604?w=400&h=400&fit=crop&crop=face	Wardrobe and laundry organizer. Makes closets feel like boutiques.	t	2026-05-16 19:09:04.833711+00	48	{"Background Checked","NRC Verified"}
62910092-aafb-47de-b4c9-d6cfb565ac49	Chibwe Musonda	5.00	34	https://images.unsplash.com/photo-1603415526960-f7e0328c63b1?w=400&h=400&fit=crop&crop=face	Hotel-standard cleaning from 3 years at Intercontinental Lusaka.	t	2026-05-16 19:09:04.833711+00	60	{"Background Checked","NRC Verified","ID Verified","Perfect Rating"}
e4559c3d-442e-4b90-92a9-c49ddd4ab927	Felicity Zimba	4.70	53	https://images.unsplash.com/photo-1614644147724-2d4785d69962?w=400&h=400&fit=crop&crop=face	Airbnb and home cleaning. Guests love her attention to detail.	t	2026-05-16 19:09:04.833711+00	52	{"Background Checked","NRC Verified"}
cb7f01a4-4052-445f-927e-b448da898a66	Daniel Nkonde	4.60	47	https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=400&h=400&fit=crop&crop=face	Repairs and maintenance specialist. Carpentry, plumbing, and painting.	t	2026-05-16 19:09:04.833711+00	75	{"Background Checked","NRC Verified","ID Verified"}
0803be5b-37b8-4eb9-9806-7c54ffdfeadf	Yvonne Kapumba	4.90	88	https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&h=400&fit=crop&crop=face	Senior domestic professional. 7 years experience in Lusaka's top residences.	t	2026-05-16 19:09:04.833711+00	62	{"Background Checked","NRC Verified","ID Verified","Top Rated"}
e71bb763-99b5-43dd-b8df-8ef01e7d1b05	Kelvin Mwamba	4.80	76	https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&h=400&fit=crop&crop=face	Moving, packing, and post-move cleaning. Makes relocating stress-free.	t	2026-05-16 19:09:04.833711+00	68	{"Background Checked","NRC Verified","ID Verified"}
\.

