# Changelog

<!-- version list -->

## v0.19.0 (2026-04-24)

### Bug Fixes

- **PLAT-16**: Decorate public mcp schema
  ([`dbdd415`](https://github.com/SidhNor/sketchup-mcp-server/commit/dbdd415ccd318867439b105b94ccdeb653ae48dc))

- **semantic**: Looses semantic create element contract to allow for richer validations
  ([`4bb585f`](https://github.com/SidhNor/sketchup-mcp-server/commit/4bb585f5347efae9239dd39cad386ffd81996927))

### Documentation

- **semantic,validation**: Task and prd updates
  ([`935f36d`](https://github.com/SidhNor/sketchup-mcp-server/commit/935f36db62976c6fd68a82ca87cd670731796dc2))

- **SVR-02**: Plan further scene validation
  ([`868501a`](https://github.com/SidhNor/sketchup-mcp-server/commit/868501a9f9d41b5257d4dcf8e1171112983c1c43))

- **SVR-03**: Planning measuring tool
  ([`1141eee`](https://github.com/SidhNor/sketchup-mcp-server/commit/1141eeea3108f3173d13f531f5928cc4b313dc7e))

- **tools**: Additional guidance on MCP tool usage
  ([`1141eee`](https://github.com/SidhNor/sketchup-mcp-server/commit/1141eeea3108f3173d13f531f5928cc4b313dc7e))

### Features

- **SVR-02**: Additional scene validations on surfaceOffset
  ([`90977c4`](https://github.com/SidhNor/sketchup-mcp-server/commit/90977c4a270505c2e52b4a58c2832fbd580c6665))

- **SVR-03**: Measure_scene tool implementation
  ([`84c77e8`](https://github.com/SidhNor/sketchup-mcp-server/commit/84c77e8e503a88e456f5df5aa25d8be6885e3946))


## v0.18.0 (2026-04-22)

### Features

- **SVR-02**: Enhance request validation with supported modes and categories
  ([`f3c64d5`](https://github.com/SidhNor/sketchup-mcp-server/commit/f3c64d5862c187bf3a9e28c2e265731d960dab89))


## v0.17.0 (2026-04-21)

### Documentation

- **SEM-13**: Testing summary clarifications
  ([`2e2d664`](https://github.com/SidhNor/sketchup-mcp-server/commit/2e2d66460e1dc4d03959884f50c234d9656efa9c))

### Features

- **SEM-13**: Path drapping on terrain
  ([`b664390`](https://github.com/SidhNor/sketchup-mcp-server/commit/b66439018031a0d11f1cf4012e69a4d2b0fb1fcf))

- **SVR-01**: Validate scene baseline
  ([`d8b2a9d`](https://github.com/SidhNor/sketchup-mcp-server/commit/d8b2a9db399ed852980edebaa28bf1448af14224))


## v0.16.1 (2026-04-20)

### Bug Fixes

- **ci**: Release note generation
  ([`f0326f4`](https://github.com/SidhNor/sketchup-mcp-server/commit/f0326f464efbf57de014bcdd7140e580cb39a42a))


## v0.16.0 (2026-04-20)

### Features

- **SEM-09**: Destination resolver for semantic primitives
  ([`a085cfd`](https://github.com/SidhNor/sketchup-mcp-server/commit/a085cfd418c15a2c608e605c2a0f06949a84a295))

- **SEM-10**: Complex shape authoring and grouping
  ([`d378fbc`](https://github.com/SidhNor/sketchup-mcp-server/commit/d378fbc36030ab2c276b74dd6472d24b99def56d))

- **SEM-10,SEM-11**: Semantic placement and group features
  ([`5f68a1d`](https://github.com/SidhNor/sketchup-mcp-server/commit/5f68a1da9ff971fad7853d46ee7407de9fd7d09b))


## v0.15.0 (2026-04-18)

### Bug Fixes

- **PLAT-14**: Enforce native tool runtime invocation and failure translation
  ([`c9c7493`](https://github.com/SidhNor/sketchup-mcp-server/commit/c9c7493b7f2ecea409940eb0e306ba7d6b9a2e88))

### Documentation

- **PLAT-14**: Finalize task and technical plan
  ([`b0142bb`](https://github.com/SidhNor/sketchup-mcp-server/commit/b0142bbd92c22c21dc988a55a44c631db7991a19))

### Features

- **PLAT-14**: Establish native tool contracts and shared response conventions
  ([`2bb9781`](https://github.com/SidhNor/sketchup-mcp-server/commit/2bb97812d7e36f410a08b32a0b1fef84f7f78e38))

- **PLAT-15**: Add selectors to list and find entities
  ([`d7d03cf`](https://github.com/SidhNor/sketchup-mcp-server/commit/d7d03cf479b83b319b549f32831a4f1565f74fee))

### Refactoring

- **PLAT-14**: Remove low-value tools and rename transform_entities
  ([`44665ae`](https://github.com/SidhNor/sketchup-mcp-server/commit/44665ae4ab5ca9117ff9e230d2d2cb302c3cee0f))


## v0.14.0 (2026-04-17)

### Documentation

- **platform**: Define PLAT-14 native MCP tool contract task
  ([`28b1023`](https://github.com/SidhNor/sketchup-mcp-server/commit/28b1023c9ef6c3a5f45751332df0665da4286fc9))

- **sem-08**: Finalize remaining-family migration plan
  ([`2b2cfe6`](https://github.com/SidhNor/sketchup-mcp-server/commit/2b2cfe663fd88b442ab37a9c3adb445995c7198d))

### Features

- **SEM-07**: Add hierarchy maintenance primitives
  ([`411d05b`](https://github.com/SidhNor/sketchup-mcp-server/commit/411d05b3a3cc8403685e68b9b1a004259a44ca81))

- **SEM-08**: Complete builder-native v2 migration for remaining families
  ([`62a9a75`](https://github.com/SidhNor/sketchup-mcp-server/commit/62a9a750baa6cdc743e4fd8d3ba9df9fd01b3203))

- **semantic**: Cut over create_site_element to sectioned contract
  ([`00de75b`](https://github.com/SidhNor/sketchup-mcp-server/commit/00de75bb8eb7fa7251064710d7344aa652b1ce46))


## v0.13.1 (2026-04-17)

### Bug Fixes

- **release**: Clean dist before preparing versioned rbz
  ([`47c5837`](https://github.com/SidhNor/sketchup-mcp-server/commit/47c58376bba75b2f92d4785a21c63f66d5e66672))

- **release**: Commit VERSION in semantic-release updates
  ([`6bd5bd1`](https://github.com/SidhNor/sketchup-mcp-server/commit/6bd5bd12d161bd1ae512c4d593474a6fdac84721))


## v0.13.0 (2026-04-17)

### Bug Fixes

- **packaging**: Create rbz destination directory before archive write
  ([`2a62bef`](https://github.com/SidhNor/sketchup-mcp-server/commit/2a62bef546fd6b153e39508ecd86edfc78128593))

- **PLAT-10**: Deep-stringify native MCP tool arguments
  ([`edc5ef0`](https://github.com/SidhNor/sketchup-mcp-server/commit/edc5ef03b63a53eff7a96bd4bddbba30aa76fbe0))

### Documentation

- **PLAT-12**: Finalize runtime-layer support-tree plan
  ([`3720b9f`](https://github.com/SidhNor/sketchup-mcp-server/commit/3720b9fcb58bebd5fb5fcaccaabd99c7db9dab5b))

- **PLAT-13**: Finalize python bridge retirement plan
  ([`f68d916`](https://github.com/SidhNor/sketchup-mcp-server/commit/f68d9167864913ab435bb0d6bee82a5024089023))

- **SEM-06**: Finalize sectioned contract cutover plan
  ([`dd8045b`](https://github.com/SidhNor/sketchup-mcp-server/commit/dd8045b59385a2095ba8fde0afd4434d1e1d5106))

- **SEM-07**: Finalize hierarchy maintenance plan
  ([`d9c8b59`](https://github.com/SidhNor/sketchup-mcp-server/commit/d9c8b59e0b8ac111250168220c64471cb8bd8dbb))

- **SEM-08**: Adjust scope to extend create_site_element
  ([`f238553`](https://github.com/SidhNor/sketchup-mcp-server/commit/f2385539d816b2b4649d38e129851d1c8acd0d16))

### Features

- **PLAT-10**: Migrate the current tool surface to Ruby native MCP
  ([`4675c56`](https://github.com/SidhNor/sketchup-mcp-server/commit/4675c56c6db5334af9fb3ae32f60f6c826259f3c))

### Refactoring

- **PLAT-12**: Reorganize Ruby support tree by runtime layer
  ([`7b91759`](https://github.com/SidhNor/sketchup-mcp-server/commit/7b917591953f1777a16dc732f1c5aa679c7c48d9))

- **PLAT-13**: Remove python bridge and runtime
  ([`2d5a640`](https://github.com/SidhNor/sketchup-mcp-server/commit/2d5a640a0c068a5156492da1c10522abab6b3672))


## v0.12.2 (2026-04-16)

### Bug Fixes

- **PLAT-10**: Align native MCP contracts with Python parity
  ([`a1df2c3`](https://github.com/SidhNor/sketchup-mcp-server/commit/a1df2c3ac1fb07993bf7898d6ba742e6b27149de))


## v0.12.1 (2026-04-16)

### Bug Fixes

- **PLAT-10**: Wire native runtime commands and align tool schemas
  ([`b088f4b`](https://github.com/SidhNor/sketchup-mcp-server/commit/b088f4b9da31d786e8733b448b79aba1ba9acd4e))


## v0.12.0 (2026-04-16)

### Documentation

- **PLAT-10**: Technical specs
  ([`22dd213`](https://github.com/SidhNor/sketchup-mcp-server/commit/22dd213143dfc491c129c23bfa4c9dd9e2622dc2))

- **PLAT-12,PLAT-13**: New tasks
  ([`424766e`](https://github.com/SidhNor/sketchup-mcp-server/commit/424766e3f24bab5ab4be61b793d81fe1eca4d289))

### Features

- **PLAT-10**: Make Ruby native runtime the canonical tool surface
  ([`326b4d6`](https://github.com/SidhNor/sketchup-mcp-server/commit/326b4d6149d9b3a56a1d8c8a7d5d0e24d65da6b4))


## v0.11.2 (2026-04-16)

### Refactoring

- **ci**: Artifact upload changes
  ([`227e3b4`](https://github.com/SidhNor/sketchup-mcp-server/commit/227e3b4bcf1dc61cb9d0c40917e9c6f00fee4dfa))


## v0.11.1 (2026-04-16)

### Refactoring

- **PLAT-11**: Extract remaining Ruby modeling command seams
  ([`c92af9f`](https://github.com/SidhNor/sketchup-mcp-server/commit/c92af9f6bed1b6a50bd7e28645b63221d0610263))


## v0.11.0 (2026-04-16)

### Documentation

- **PLAT-09,PLAT-11**: Planning tech stack
  ([`342e1b1`](https://github.com/SidhNor/sketchup-mcp-server/commit/342e1b1805653750591acf87707714ddd59c4da2))

- **platfrom**: Tasks for mcp move to ruby
  ([`327b7c9`](https://github.com/SidhNor/sketchup-mcp-server/commit/327b7c9da0072ea97674d8534f04f1e145619375))

### Features

- **PLAT-09**: Build ruby-native packaging and runtime foundations
  ([`f27a687`](https://github.com/SidhNor/sketchup-mcp-server/commit/f27a6874728c1f949a526221c9cab579fcd0d761))

### Refactoring

- **PLAT-08**: Align coding guidelines
  ([`61a5982`](https://github.com/SidhNor/sketchup-mcp-server/commit/61a5982f4c7eeade7360ff617ffe09285c10c4af))


## v0.10.0 (2026-04-16)

### Documentation

- **PLAT-08**: Coding guidelines and alignment
  ([`66b0696`](https://github.com/SidhNor/sketchup-mcp-server/commit/66b06969d232819f9352b8fec8165e1feffc9eaf))

### Features

- **PLAT-07**: Ruby mcp
  ([`606e4d7`](https://github.com/SidhNor/sketchup-mcp-server/commit/606e4d77435c63d05f5dc1c2ab27eee7ad8f63c2))


## v0.9.0 (2026-04-16)

### Documentation

- **arch**: Add ADR and new ruby coding guidelines
  ([`05d8a8e`](https://github.com/SidhNor/sketchup-mcp-server/commit/05d8a8e7e55f22347241eb64466fc34426b7edbd))

- **PLAT-07**: Planning ruby MCP spike
  ([`932d37b`](https://github.com/SidhNor/sketchup-mcp-server/commit/932d37b586f30b7f7e628f547a8b22cf9fe5b685))

- **SEM-05**: Signal for other contract and spike for it
  ([`8cfaba4`](https://github.com/SidhNor/sketchup-mcp-server/commit/8cfaba4f034c5c2cea91436a7b6c3b6b5e489974))

### Features

- **SME-05**: New contract spike
  ([`aa865d5`](https://github.com/SidhNor/sketchup-mcp-server/commit/aa865d5c857bd1712f9329d35c8560f8b544a220))


## v0.8.2 (2026-04-15)

### Bug Fixes

- **SEM-04**: Tree proxy updates
  ([`135ffe2`](https://github.com/SidhNor/sketchup-mcp-server/commit/135ffe2f217e447fa9ba58db1900082231e00912))


## v0.8.1 (2026-04-15)

### Bug Fixes

- **SEM-04**: Planar shape updates
  ([`104f304`](https://github.com/SidhNor/sketchup-mcp-server/commit/104f304e5d4eea47816287ede5601ded2025cc4f))


## v0.8.0 (2026-04-15)

### Features

- **SEM-04**: Tree proxy shape decoration
  ([`8b37b0f`](https://github.com/SidhNor/sketchup-mcp-server/commit/8b37b0ffe4876bb0691d084f7f66668ebf87ba38))


## v0.7.0 (2026-04-15)

### Features

- **SEM-03**: Add metadata mutation to managed objects
  ([`ccca259`](https://github.com/SidhNor/sketchup-mcp-server/commit/ccca2599b78d0c94286ed2ad7951c53a4513f09a))


## v0.6.0 (2026-04-15)

### Documentation

- **SEM-02**: Refene plan with premortem
  ([`42a0b78`](https://github.com/SidhNor/sketchup-mcp-server/commit/42a0b78dff707f6d9a9986f7cb9713d97af8adab))

- **SEM-03**: Catter for nested objects
  ([`4696ca7`](https://github.com/SidhNor/sketchup-mcp-server/commit/4696ca7eb3e0db76fb0dd49601671316c27b823a))

### Features

- **SEM-02**: Additional semantic creation shapes
  ([`ff80896`](https://github.com/SidhNor/sketchup-mcp-server/commit/ff808961dff98c504721a3a4c4d60e8ef0a353a1))


## v0.5.1 (2026-04-14)

### Bug Fixes

- **PLAT-04**: Add additional tool descriptions
  ([`6c7d7d1`](https://github.com/SidhNor/sketchup-mcp-server/commit/6c7d7d1a65bbf7ecf837ec295ceb0bc004a56713))


## v0.5.0 (2026-04-14)

### Features

- **PLAT-04**: Add MCP tool decoration contract
  ([`7cd1584`](https://github.com/SidhNor/sketchup-mcp-server/commit/7cd1584e7cd0d06fdabaf6f0ed1b07dd64d0ea54))


## v0.4.0 (2026-04-14)

### Documentation

- **PLAT-04**: Planned mcp tool description updates
  ([`4db2b29`](https://github.com/SidhNor/sketchup-mcp-server/commit/4db2b2974e93ff95eedfe5980dc35ad1b5bdae47))

- **SEM-02**: Planning
  ([`4ed7fa9`](https://github.com/SidhNor/sketchup-mcp-server/commit/4ed7fa9199ae6306869e9692e6b04f1e85ae65b0))

- **SEM-03**: Planned entity metadata
  ([`d0a1ef0`](https://github.com/SidhNor/sketchup-mcp-server/commit/d0a1ef04961b13ca8457a143798651f0da4009c4))

### Features

- **SEM-01**: Implement initial create site element
  ([`c3bd634`](https://github.com/SidhNor/sketchup-mcp-server/commit/c3bd6342eb260ffffe3c7a57b65d1df91ef6fbc8))


## v0.3.0 (2026-04-14)

### Documentation

- **hlds**: Update hlds and PLAT-05 planning
  ([`ed1bbf5`](https://github.com/SidhNor/sketchup-mcp-server/commit/ed1bbf504aa57f804387ca8c4570ecd20ad10a22))

- **PLAT-04**: Add MCP tooling decorators
  ([`6cf1234`](https://github.com/SidhNor/sketchup-mcp-server/commit/6cf12348073627e6c6a6b260ed4f7d62ac71e593))

- **scene**: Refine scene modelling hld and prd
  ([`7c356d9`](https://github.com/SidhNor/sketchup-mcp-server/commit/7c356d910d5fe1e6e54a181296dd12922db947bf))

- **SEM**: Initial breakdown
  ([`67a4823`](https://github.com/SidhNor/sketchup-mcp-server/commit/67a482342b7e70ae374b8797deb4f26333e6ac0e))

- **SEM-01**: Planning
  ([`0861719`](https://github.com/SidhNor/sketchup-mcp-server/commit/0861719e112fd3a45ecc063de72b288fae9e0589))

- **signal**: Add suggestion for contract change
  ([`95cb689`](https://github.com/SidhNor/sketchup-mcp-server/commit/95cb68980b025fbf6382e647fc440bba84179233))

- **STI-01**: Planning
  ([`154c352`](https://github.com/SidhNor/sketchup-mcp-server/commit/154c352b4076ecfd9938373fb3dc4881bfe40434))

- **STI-02**: Planning
  ([`d4fa3e3`](https://github.com/SidhNor/sketchup-mcp-server/commit/d4fa3e333c8af1a2800c5c465de6499d7f541f8b))

- **targeting**: Mvp tasks for targeting
  ([`b567ec5`](https://github.com/SidhNor/sketchup-mcp-server/commit/b567ec5f11323a7a18ff71363c1fb9720a1f2350))

### Features

- **STI-01**: Add find_entities MVP
  ([`c91a3bd`](https://github.com/SidhNor/sketchup-mcp-server/commit/c91a3bdea98e38265d1e2a252b1df8f93ba1db19))

- **STI-02**: Sample surface z implementation
  ([`61c8ca4`](https://github.com/SidhNor/sketchup-mcp-server/commit/61c8ca4f88e0e910218cec977f0e0d99eda73a0b))


## v0.2.2 (2026-04-14)

### Bug Fixes

- **release**: Explicitly declare assets for PSR
  ([`d668bd5`](https://github.com/SidhNor/sketchup-mcp-server/commit/d668bd551617e7a79448d41d529e8f459d631b4a))


## v0.2.1 (2026-04-14)

### Bug Fixes

- **PLAT-02**: Extension loading and unit precision
  ([`cd06667`](https://github.com/SidhNor/sketchup-mcp-server/commit/cd066678b1b4302ff7aa6e67bb6124e16a714475))

- **release**: Ensure uv.lock version bump during release
  ([`e44fa65`](https://github.com/SidhNor/sketchup-mcp-server/commit/e44fa65524ed9309ccc96ac8b091e83381c81a3b))


## v0.2.0 (2026-04-14)

### Documentation

- **guidelines**: Additional ruby guidelines
  ([`5731288`](https://github.com/SidhNor/sketchup-mcp-server/commit/57312883211ef06eb7cdcfe52dafc6ad3e112fea))

- **PLAT**: Plans for platform tasks
  ([`29a2191`](https://github.com/SidhNor/sketchup-mcp-server/commit/29a2191f1d307b017876ae4e90afd43f38ac7717))

- **PLAT-02**: Update plan
  ([`b6719dd`](https://github.com/SidhNor/sketchup-mcp-server/commit/b6719dd78731b49a630d436a897c765bb7675c4b))

- **prd**: Add prds and domain overview
  ([`456a22e`](https://github.com/SidhNor/sketchup-mcp-server/commit/456a22efda1305e8118f0f8604999c0a415e1e1d))

- **skills**: Refine prd creation skill
  ([`e67d3b8`](https://github.com/SidhNor/sketchup-mcp-server/commit/e67d3b896beeb1540d12c9308a169da2256700bb))

- **tasks**: Add platform task specifications and structure
  ([`2fcbf53`](https://github.com/SidhNor/sketchup-mcp-server/commit/2fcbf53ab297473efe53a7a7958529934df9425a))

### Features

- **PLAT-03**: Decompose python MCP adapter
  ([`063ef9e`](https://github.com/SidhNor/sketchup-mcp-server/commit/063ef9e375e1c60a0a309233a47429a1164b6cd7))

### Refactoring

- **PLAT-02**: Extract ruby SketchUp adapters and serializers
  ([`fad22cc`](https://github.com/SidhNor/sketchup-mcp-server/commit/fad22cc56d7caa854e151c03e6196e3f8212d6f4))

- **ruby**: Decompose runtime boundaries
  ([`fd5cac0`](https://github.com/SidhNor/sketchup-mcp-server/commit/fd5cac015ba9ec6a8ef865aeff7fa1a3a08c485e))


## v0.1.0 (2026-04-11)

- Initial Release
