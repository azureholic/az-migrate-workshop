import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './HyperVDiscoverySourceSlide.module.css'

export default function HyperVDiscoverySourceSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.hyperVDiscoverySource}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 7</p>
          <h2>Hyper-V <span className={styles.highlight}>Discovery Source</span></h2>
          <p className={styles.subtitle}>
            Add the Hyper-V host as a discovery source for the appliance
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <h3 className={styles.sectionTitle}>Add Single Item</h3>

            <div className={styles.fieldGroup}>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>IP Address</span>
                <code className={styles.fieldCode}>192.168.100.1</code>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Map Credentials</span>
                <span className={styles.fieldValue}>datacenter</span>
                <span className={styles.fieldHint}>As named in the previous step</span>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/Hyperv-Discovery-Host.png"
              alt="Hyper-V Discovery Source configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
