import CoverSlide from './src/slides/CoverSlide.jsx'
import EnvironmentSetupSlide from './src/slides/EnvironmentSetupSlide.jsx'
import ConnectApplianceSlide from './src/slides/ConnectApplianceSlide.jsx'
import ConfigureApplianceSlide from './src/slides/ConfigureApplianceSlide.jsx'
import HyperVHostCredentialsSlide from './src/slides/HyperVHostCredentialsSlide.jsx'
import WindowsUpdateSlide from './src/slides/WindowsUpdateSlide.jsx'
import AppliancePrerequisitesSlide from './src/slides/AppliancePrerequisitesSlide.jsx'
import CheckApplianceSlide from './src/slides/CheckApplianceSlide.jsx'
import HyperVDiscoverySourceSlide from './src/slides/HyperVDiscoverySourceSlide.jsx'
import ServerCredentialsUbuntuSlide from './src/slides/ServerCredentialsUbuntuSlide.jsx'
import ServerCredentialsWinDCSlide from './src/slides/ServerCredentialsWinDCSlide.jsx'
import ServerCredentialsPGSlide from './src/slides/ServerCredentialsPGSlide.jsx'
import StartDiscoverySlide from './src/slides/StartDiscoverySlide.jsx'
import OnPremiseCostsSlide from './src/slides/OnPremiseCostsSlide.jsx'
import BusinessCaseSlide from './src/slides/BusinessCaseSlide.jsx'
import BuildBusinessCaseSlide from './src/slides/BuildBusinessCaseSlide.jsx'
import SelectWorkloadsSlide from './src/slides/SelectWorkloadsSlide.jsx'
import BusinessCaseSettingsSlide from './src/slides/BusinessCaseSettingsSlide.jsx'
import BusinessCaseExploreSlide from './src/slides/BusinessCaseExploreSlide.jsx'
import LiftShiftChapterSlide from './src/slides/LiftShiftChapterSlide.jsx'
import AssessmentLiftShiftSlide from './src/slides/AssessmentLiftShiftSlide.jsx'
import ReviewAssessmentLiftShiftSlide from './src/slides/ReviewAssessmentLiftShiftSlide.jsx'
import CreateWaveUbuntuSlide from './src/slides/CreateWaveUbuntuSlide.jsx'
import WavePlanningSlide from './src/slides/WavePlanningSlide.jsx'
import ConfigureWaveSlide from './src/slides/ConfigureWaveSlide.jsx'
import SetupAzureMigrateSlide from './src/slides/SetupAzureMigrateSlide.jsx'
import RegisterHyperVHostsSlide from './src/slides/RegisterHyperVHostsSlide.jsx'
import FinalizeRegistrationSlide from './src/slides/FinalizeRegistrationSlide.jsx'
import ExecuteWaveSlide from './src/slides/ExecuteWaveSlide.jsx'
import ReplicationSlide from './src/slides/ReplicationSlide.jsx'
import MigrateLiftShiftSlide from './src/slides/MigrateLiftShiftSlide.jsx'
import DatabaseMigrationSlide from './src/slides/DatabaseMigrationSlide.jsx'
import DbMigrateSetupSlide from './src/slides/DbMigrateSetupSlide.jsx'
import DbMigrateRuntimeSlide from './src/slides/DbMigrateRuntimeSlide.jsx'
import DbMigrateSourceSlide from './src/slides/DbMigrateSourceSlide.jsx'
import DbMigrateTargetSlide from './src/slides/DbMigrateTargetSlide.jsx'
import DbMigrateDatabasesSlide from './src/slides/DbMigrateDatabasesSlide.jsx'
import DbMigrateSummarySlide from './src/slides/DbMigrateSummarySlide.jsx'
import { GenericThankYouSlide as ThankYouSlide } from '@deckio/deck-engine'

export default {
  id: 'azure-migrate-workshop',
  title: 'Azure Migrate Workshop',
  subtitle: 'Handson moving workloads to Azure',
  description: 'Handson moving workloads to Azure',
  meta: {
    seededTemplate: true,
    contentStatus: 'sample',
    contextPolicy: 'ignore-sample-content-until-user-replaces-it',
  },
  icon: '🎴',
  accent: '#3b82f6',
  theme: 'light',
  appearance: 'light',
  order: 1,
  slides: [
    CoverSlide,
    EnvironmentSetupSlide,
    ConnectApplianceSlide,
    ConfigureApplianceSlide,
    WindowsUpdateSlide,
    AppliancePrerequisitesSlide,
    CheckApplianceSlide,
    HyperVHostCredentialsSlide,
    HyperVDiscoverySourceSlide,
    ServerCredentialsUbuntuSlide,
    ServerCredentialsWinDCSlide,
    ServerCredentialsPGSlide,
    StartDiscoverySlide,
    OnPremiseCostsSlide,
    BusinessCaseSlide,
    BuildBusinessCaseSlide,
    SelectWorkloadsSlide,
    BusinessCaseSettingsSlide,
    BusinessCaseExploreSlide,
    LiftShiftChapterSlide,
    AssessmentLiftShiftSlide,
    ReviewAssessmentLiftShiftSlide,
    CreateWaveUbuntuSlide,
    WavePlanningSlide,
    ConfigureWaveSlide,
    SetupAzureMigrateSlide,
    RegisterHyperVHostsSlide,
    FinalizeRegistrationSlide,
    ExecuteWaveSlide,
    ReplicationSlide,
    MigrateLiftShiftSlide,
    DatabaseMigrationSlide,
    DbMigrateSetupSlide,
    DbMigrateRuntimeSlide,
    DbMigrateSourceSlide,
    DbMigrateTargetSlide,
    DbMigrateDatabasesSlide,
    DbMigrateSummarySlide,
    ThankYouSlide,
  ],
}
