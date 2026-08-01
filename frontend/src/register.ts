import { ComponentType, lazy } from 'react';
import { featureRegistry } from '@/shared/services/featureRegistry';

// Helper: widen the lazy-loaded module's default-export type from the concrete
// `FC<P>` it was authored as to the `ComponentType<unknown>` that
// `featureRegistry.FeatureRoute.component` expects. Every page is a different
// `FC<P>` but the registry stores them in one typed list, and `FC<{}>` does not
// satisfy `FC<unknown>` under React's strict prop variance. The cast happens
// here, once, instead of at every call site.
//
// Not generic over the props type: these loaders re-wrap a named export as
// `.then(m => ({ default: m.Named }))`, and inferring a type parameter through
// that re-wrap makes tsc resolve it to `never`.
const lazyPage = (
  loader: () => Promise<{ default: unknown }>
) => lazy(loader as () => Promise<{ default: ComponentType<unknown> }>);


// Lazy-loaded supply chain page components
const SupplyChainDashboardPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.SupplyChainDashboardPage })));
const SbomsPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.SbomsPage })));
const SbomDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.SbomDetailPage })));
const SbomDiffPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.SbomDiffPage })));
const ContainerImagesPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.ContainerImagesPage })));
const ContainerImageDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.ContainerImageDetailPage })));
const AttestationsPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.AttestationsPage })));
const AttestationDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.AttestationDetailPage })));
const VendorsPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.VendorsPage })));
const VendorDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.VendorDetailPage })));
const VendorRiskDashboardPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.VendorRiskDashboardPage })));
const AssessmentDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.AssessmentDetailPage })));
const QuestionnaireDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.QuestionnaireDetailPage })));
const LicensePoliciesPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.LicensePoliciesPage })));
const LicensePolicyFormPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.LicensePolicyFormPage })));
const LicensePolicyDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.LicensePolicyDetailPage })));
const LicenseViolationsPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.LicenseViolationsPage })));
const LicenseViolationDetailPage = lazyPage(() => import('./features/supply-chain/pages').then(m => ({ default: m.LicenseViolationDetailPage })));

export function register(): void {
  // Supply chain routes — rendered dynamically via featureRegistry in DashboardPage
  featureRegistry.registerRoutes('supply-chain', [
    { path: '/supply-chain', component: SupplyChainDashboardPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/sboms', component: SbomsPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/sboms/:id', component: SbomDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/sboms/:id/diff/:diffId', component: SbomDiffPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/containers', component: ContainerImagesPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/containers/:id/*', component: ContainerImageDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/attestations', component: AttestationsPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/attestations/:id/*', component: AttestationDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/vendors', component: VendorsPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/vendors/risk-dashboard', component: VendorRiskDashboardPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/vendors/:id', component: VendorDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/vendors/:id/assessments/:assessmentId', component: AssessmentDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/vendors/:id/questionnaires/:questionnaireId', component: QuestionnaireDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/licenses', component: LicensePoliciesPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/licenses/policies', component: LicensePoliciesPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/licenses/policies/new', component: LicensePolicyFormPage, permission: 'supply_chain.write' },
    { path: '/supply-chain/licenses/policies/:id/edit', component: LicensePolicyFormPage, permission: 'supply_chain.write' },
    { path: '/supply-chain/licenses/policies/:id', component: LicensePolicyDetailPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/licenses/violations', component: LicenseViolationsPage, permission: 'supply_chain.read' },
    { path: '/supply-chain/licenses/violations/:id', component: LicenseViolationDetailPage, permission: 'supply_chain.read' },
  ]);

  // Supply chain navigation section
  featureRegistry.registerNavSections('supply-chain', [{
    id: 'supply-chain',
    name: 'Supply Chain',
    permissions: ['supply_chain.read'],
    collapsible: true,
    defaultExpanded: false,
    order: 22,
    items: [
      { label: 'Overview', path: '/app/supply-chain', icon: 'Shield', permission: 'supply_chain.read', order: 1 },
      { label: 'SBOMs', path: '/app/supply-chain/sboms', icon: 'FileCode', permission: 'supply_chain.read', order: 2 },
      { label: 'Attestations', path: '/app/supply-chain/attestations', icon: 'CircleCheckBig', permission: 'supply_chain.read', order: 3 },
      { label: 'Container Images', path: '/app/supply-chain/containers', icon: 'Package', permission: 'supply_chain.read', order: 4 },
      { label: 'License Compliance', path: '/app/supply-chain/licenses', icon: 'Scale', permission: 'supply_chain.read', order: 5 },
      { label: 'Vendor Risk', path: '/app/supply-chain/vendors', icon: 'Building2', permission: 'supply_chain.read', order: 6 },
    ],
  }]);
}
