import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './StartDiscoverySlide.module.css'

export default function StartDiscoverySlide({ index, project }) {
  return (
    <Slide index={index} className={styles.startDiscovery}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 11</p>
          <h2>Start <span className={styles.highlight}>Discovery</span></h2>
          <p className={styles.subtitle}>
            Review your credentials list and kick off the discovery process
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <div className={styles.instruction}>
                <div className={styles.stepNumber}>1</div>
                <p>Verify you have a complete list of credentials configured</p>
              </div>
              <div className={styles.instruction}>
                <div className={styles.stepNumber}>2</div>
                <p>Hit the <strong>Start Discovery</strong> button</p>
              </div>
              <div className={styles.instruction}>
                <div className={styles.stepNumber}>3</div>
                <p>Check on the Hyper-V host (in the appliance) if the discovery has been initiated</p>
              </div>
            </div>

            <div className={styles.callout}>
              <strong>From this point forward</strong> you no longer need the connection to the appliance VM. All next steps are in the Azure Portal and on the Hyper-V host.
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/StartDiscovery.png"
              alt="Start Discovery with credentials list"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
