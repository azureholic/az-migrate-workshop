import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './RegisterHyperVHostsSlide.module.css'

export default function RegisterHyperVHostsSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.registerHosts}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 24</p>
          <h2>Register <span className={styles.highlight}>Hyper-V Hosts</span></h2>
          <p className={styles.subtitle}>
            Install the Azure Site Recovery Provider on the VM-DC
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Download and install <strong>AzureSiteRecoveryProvider.exe</strong> on the VM-DC. Use the browser on that machine to make it easy.</p>
              <p>Also download the <strong>registration key file</strong>.</p>
              <p>Run the installer and the registration. When successful, the registration wizard should show: <em>"The Server was registered in the Azure Site Recovery vault"</em>.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/RegisterHyperVHosts.png"
              alt="Register Hyper-V Hosts"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
